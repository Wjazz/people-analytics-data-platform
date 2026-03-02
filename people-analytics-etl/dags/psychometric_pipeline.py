"""
Psychometric ETL Pipeline DAG.

Automated daily pipeline that:
1. Extracts assessment data from CSV files
2. Transforms raw scores (normalization, PsyCap calculation)
3. Loads into PostgreSQL data warehouse
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.decorators import task
from airflow.providers.postgres.hooks.postgres import PostgresHook
import pandas as pd
import sys
from pathlib import Path

# Add src directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from extractors.csv_extractor import CSVExtractor
from transformers.big_five_normalizer import BigFiveNormalizer
from transformers.psycap_calculator import PsyCapCalculator


# DAG default arguments
default_args = {
    'owner': 'james_alvarado',
    'depends_on_past': False,
    'email': ['james.alvarado@email.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

# Create DAG
with DAG(
    dag_id='psychometric_etl_pipeline',
    default_args=default_args,
    description='ETL pipeline for psychometric assessments (Big Five, PsyCap)',
    schedule_interval='@daily',  # Run once per day at midnight
    start_date=datetime(2024, 1, 1),
    catchup=False,  # Don't backfill historical runs
    tags=['people_analytics', 'etl', 'psychometrics'],
) as dag:
    
    @task
    def extract_big_five_csv():
        """
        Extract Big Five assessment data from CSV.
        
        Returns:
            Dict with metadata (rows_extracted, file_path)
        """
        db_conn = "postgresql://analytics_user:analytics_pass@postgres:5432/people_analytics"
        extractor = CSVExtractor(db_conn)
        
        # Extract from CSV (adjust path to your data location)
        file_path = "/opt/airflow/data/raw/big_five_assessments.csv"
        
        count = extractor.extract_from_csv(
            file_path=file_path,
            assessment_type="BigFive",
            employee_code_column="employee_code",
            assessment_date_column="assessment_date"
        )
        
        return {
            'rows_extracted': count,
            'file_path': file_path,
            'assessment_type': 'BigFive'
        }
    
    @task
    def extract_psycap_csv():
        """
        Extract PsyCap assessment data from CSV.
        
        Returns:
            Dict with metadata (rows_extracted, file_path)
        """
        db_conn = "postgresql://analytics_user:analytics_pass@postgres:5432/people_analytics"
        extractor = CSVExtractor(db_conn)
        
        file_path = "/opt/airflow/data/raw/psycap_assessments.csv"
        
        count = extractor.extract_from_csv(
            file_path=file_path,
            assessment_type="PsyCap",
            employee_code_column="employee_code",
            assessment_date_column="assessment_date"
        )
        
        return {
            'rows_extracted': count,
            'file_path': file_path,
            'assessment_type': 'PsyCap'
        }
    
    @task
    def transform_big_five(extract_metadata: dict):
        """
        Transform Big Five raw scores to T-scores.
        
        Args:
            extract_metadata: Output from extract_big_five_csv
            
        Returns:
            Dict with transformation metadata
        """
        pg_hook = PostgresHook(postgres_conn_id='postgres_default')
        engine = pg_hook.get_sqlalchemy_engine()
        
        # Read unprocessed Big Five data from staging
        query = """
            SELECT id, employee_code, assessment_date, raw_data
            FROM staging_raw_assessments
            WHERE assessment_type = 'BigFive' AND processed = FALSE
        """
        df_staging = pd.read_sql(query, engine)
        
        if df_staging.empty:
            return {'rows_transformed': 0, 'message': 'No unprocessed Big Five data'}
        
        # Extract raw scores from JSONB column
        df_scores = pd.json_normalize(df_staging['raw_data'])
        df_scores['staging_id'] = df_staging['id']
        df_scores['employee_code'] = df_staging['employee_code']
        df_scores['assessment_date'] = df_staging['assessment_date']
        
        # Normalize to T-scores
        normalizer = BigFiveNormalizer(use_sample_norms=False)
        df_normalized = normalizer.transform(df_scores)
        
        # Load to fact_big_five_assessment table
        for _, row in df_normalized.iterrows():
            # Get employee_id from dim_employee
            emp_query = f"SELECT employee_id FROM dim_employee WHERE employee_code = '{row['employee_code']}'"
            emp_result = pd.read_sql(emp_query, engine)
            
            if emp_result.empty:
                print(f"Warning: Employee {row['employee_code']} not found in dim_employee")
                continue
            
            employee_id = emp_result.iloc[0]['employee_id']
            
            # Get date_id from dim_date
            date_query = f"SELECT date_id FROM dim_date WHERE full_date = '{row['assessment_date']}'"
            date_result = pd.read_sql(date_query, engine)
            
            if date_result.empty:
                print(f"Warning: Date {row['assessment_date']} not found in dim_date")
                continue
            
            date_id = date_result.iloc[0]['date_id']
            
            # Insert into fact table
            insert_query = """
                INSERT INTO fact_big_five_assessment 
                (employee_id, assessment_date_id, 
                 openness_t_score, conscientiousness_t_score, 
                 extraversion_t_score, agreeableness_t_score, neuroticism_t_score)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (employee_id, assessment_date_id) DO UPDATE
                SET openness_t_score = EXCLUDED.openness_t_score,
                    conscientiousness_t_score = EXCLUDED.conscientiousness_t_score,
                    extraversion_t_score = EXCLUDED.extraversion_t_score,
                    agreeableness_t_score = EXCLUDED.agreeableness_t_score,
                    neuroticism_t_score = EXCLUDED.neuroticism_t_score
            """
            
            with engine.connect() as conn:
                conn.execute(
                    insert_query,
                    (employee_id, date_id,
                     row.get('openness_t_score'),
                     row.get('conscientiousness_t_score'),
                     row.get('extraversion_t_score'),
                     row.get('agreeableness_t_score'),
                     row.get('neuroticism_t_score'))
                )
        
        # Mark staging records as processed
        with engine.connect() as conn:
            conn.execute(
                "UPDATE staging_raw_assessments SET processed = TRUE WHERE assessment_type = 'BigFive' AND processed = FALSE"
            )
        
        return {
            'rows_transformed': len(df_normalized),
            'assessment_type': 'BigFive'
        }
    
    @task
    def transform_psycap(extract_metadata: dict):
        """
        Transform PsyCap raw scores to composite scores.
        
        Args:
            extract_metadata: Output from extract_psycap_csv
            
        Returns:
            Dict with transformation metadata
        """
        pg_hook = PostgresHook(postgres_conn_id='postgres_default')
        engine = pg_hook.get_sqlalchemy_engine()
        
        # Read unprocessed PsyCap data from staging
        query = """
            SELECT id, employee_code, assessment_date, raw_data
            FROM staging_raw_assessments
            WHERE assessment_type = 'PsyCap' AND processed = FALSE
        """
        df_staging = pd.read_sql(query, engine)
        
        if df_staging.empty:
            return {'rows_transformed': 0, 'message': 'No unprocessed PsyCap data'}
        
        # Extract raw scores
        df_scores = pd.json_normalize(df_staging['raw_data'])
        df_scores['staging_id'] = df_staging['id']
        df_scores['employee_code'] = df_staging['employee_code']
        df_scores['assessment_date'] = df_staging['assessment_date']
        
        # Calculate PsyCap composite
        calculator = PsyCapCalculator()
        df_psycap = calculator.transform(df_scores)
        
        # Load to fact_psycap_assessment table
        for _, row in df_psycap.iterrows():
            # Get employee_id
            emp_query = f"SELECT employee_id FROM dim_employee WHERE employee_code = '{row['employee_code']}'"
            emp_result = pd.read_sql(emp_query, engine)
            
            if emp_result.empty:
                continue
            
            employee_id = emp_result.iloc[0]['employee_id']
            
            # Get date_id
            date_query = f"SELECT date_id FROM dim_date WHERE full_date = '{row['assessment_date']}'"
            date_result = pd.read_sql(date_query, engine)
            
            if date_result.empty:
                continue
            
            date_id = date_result.iloc[0]['date_id']
            
            # Insert into fact table
            insert_query = """
                INSERT INTO fact_psycap_assessment 
                (employee_id, assessment_date_id, 
                 hope_score, efficacy_score, resilience_score, optimism_score, psycap_composite)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (employee_id, assessment_date_id) DO UPDATE
                SET hope_score = EXCLUDED.hope_score,
                    efficacy_score = EXCLUDED.efficacy_score,
                    resilience_score = EXCLUDED.resilience_score,
                    optimism_score = EXCLUDED.optimism_score,
                    psycap_composite = EXCLUDED.psycap_composite
            """
            
            with engine.connect() as conn:
                conn.execute(
                    insert_query,
                    (employee_id, date_id,
                     row.get('hope'),
                     row.get('self_efficacy'),
                     row.get('resilience'),
                     row.get('optimism'),
                     row.get('psycap_composite'))
                )
        
        # Mark as processed
        with engine.connect() as conn:
            conn.execute(
                "UPDATE staging_raw_assessments SET processed = TRUE WHERE assessment_type = 'PsyCap' AND processed = FALSE"
            )
        
        return {
            'rows_transformed': len(df_psycap),
            'assessment_type': 'PsyCap'
        }
    
    @task
    def refresh_analytical_views():
        """
        Refresh materialized views for analytics.
        
        Returns:
            Dict with refresh metadata
        """
        pg_hook = PostgresHook(postgres_conn_id='postgres_default')
        
        views_to_refresh = [
            'view_employee_psychometric_profile',
            'view_turnover_risk',
            'view_department_psychometrics'
        ]
        
        with pg_hook.get_conn() as conn:
            cursor = conn.cursor()
            for view in views_to_refresh:
                # Note: These are regular views, not materialized
                # If you want materialized views, change to:
                # cursor.execute(f"REFRESH MATERIALIZED VIEW {view}")
                print(f"View {view} ready for querying")
            cursor.close()
        
        return {
            'views_refreshed': len(views_to_refresh),
            'timestamp': datetime.now().isoformat()
        }
    
    # Define task dependencies (DAG structure)
    big_five_data = extract_big_five_csv()
    psycap_data = extract_psycap_csv()
    
    # Transform tasks (can run in parallel)
    big_five_transformed = transform_big_five(big_five_data)
    psycap_transformed = transform_psycap(psycap_data)
    
    # Refresh views after all transformations complete
    [big_five_transformed, psycap_transformed] >> refresh_analytical_views()
