"""
CSV Extractor for Psychometric Assessment Data.

Reads CSV files containing assessment responses and loads them into staging tables.
"""

import logging
from typing import Dict, List, Optional
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

logger = logging.getLogger(__name__)


class CSVExtractor:
    """Extracts psychometric assessment data from CSV files."""
    
    def __init__(self, db_connection_string: str):
        """
        Initialize CSV extractor.
        
        Args:
            db_connection_string: PostgreSQL connection string
                Example: "postgresql://user:pass@localhost:5432/people_analytics"
        """
        self.engine = create_engine(db_connection_string)
        self.Session = sessionmaker(bind=self.engine)
        logger.info(f"CSVExtractor initialized with connection: {db_connection_string}")
    
    def extract_from_csv(
        self, 
        file_path: str, 
        assessment_type: str,
        employee_code_column: str = "employee_code",
        assessment_date_column: str = "assessment_date"
    ) -> int:
        """
        Extract assessment data from CSV and load into staging table.
        
        Args:
            file_path: Path to CSV file
            assessment_type: Type of assessment ("BigFive", "DarkTetrad", "Holland", "PsyCap")
            employee_code_column: Name of column containing employee code
            assessment_date_column: Name of column containing assessment date
            
        Returns:
            Number of records inserted into staging
            
        Raises:
            FileNotFoundError: If CSV file doesn't exist
            ValueError: If required columns are missing
        """
        file_path_obj = Path(file_path)
        if not file_path_obj.exists():
            raise FileNotFoundError(f"CSV file not found: {file_path}")
        
        logger.info(f"Reading CSV file: {file_path}")
        df = pd.read_csv(file_path)
        
        # Validate required columns
        required_cols = [employee_code_column, assessment_date_column]
        missing_cols = [col for col in required_cols if col not in df.columns]
        if missing_cols:
            raise ValueError(f"Missing required columns: {missing_cols}")
        
        logger.info(f"Loaded {len(df)} records from CSV")
        
        # Convert DataFrame to staging records
        records_inserted = 0
        session = self.Session()
        
        try:
            for _, row in df.iterrows():
                # Convert row to dictionary, excluding employee_code and date
                # (they'll be separate columns in staging)
                exclude_cols = {employee_code_column, assessment_date_column}
                raw_data = {
                    col: row[col] 
                    for col in df.columns 
                    if col not in exclude_cols and pd.notna(row[col])
                }
                
                # Insert into staging table
                insert_query = """
                    INSERT INTO staging_raw_assessments 
                    (employee_code, assessment_type, assessment_date, raw_data, processed)
                    VALUES (:employee_code, :assessment_type, :assessment_date, :raw_data, FALSE)
                """
                
                session.execute(
                    insert_query,
                    {
                        "employee_code": row[employee_code_column],
                        "assessment_type": assessment_type,
                        "assessment_date": row[assessment_date_column],
                        "raw_data": raw_data
                    }
                )
                records_inserted += 1
            
            session.commit()
            logger.info(f"Successfully inserted {records_inserted} records into staging")
            
        except Exception as e:
            session.rollback()
            logger.error(f"Error inserting records: {e}")
            raise
        finally:
            session.close()
        
        return records_inserted
    
    def extract_multiple_csvs(
        self, 
        file_configs: List[Dict[str, str]]
    ) -> Dict[str, int]:
        """
        Extract data from multiple CSV files.
        
        Args:
            file_configs: List of dicts with keys: 
                - 'file_path': Path to CSV
                - 'assessment_type': Type of assessment
                - 'employee_code_column' (optional)
                - 'assessment_date_column' (optional)
                
        Returns:
            Dictionary mapping file_path to number of records inserted
            
        Example:
            >>> extractor = CSVExtractor("postgresql://...")
            >>> configs = [
            ...     {
            ...         'file_path': 'data/big_five_2024.csv',
            ...         'assessment_type': 'BigFive'
            ...     },
            ...     {
            ...         'file_path': 'data/psycap_2024.csv',
            ...         'assessment_type': 'PsyCap'
            ...     }
            ... ]
            >>> results = extractor.extract_multiple_csvs(configs)
            >>> print(results)
            {'data/big_five_2024.csv': 150, 'data/psycap_2024.csv': 150}
        """
        results = {}
        
        for config in file_configs:
            file_path = config['file_path']
            assessment_type = config['assessment_type']
            employee_col = config.get('employee_code_column', 'employee_code')
            date_col = config.get('assessment_date_column', 'assessment_date')
            
            try:
                count = self.extract_from_csv(
                    file_path=file_path,
                    assessment_type=assessment_type,
                    employee_code_column=employee_col,
                    assessment_date_column=date_col
                )
                results[file_path] = count
                logger.info(f"✓ Processed {file_path}: {count} records")
                
            except Exception as e:
                logger.error(f"✗ Failed to process {file_path}: {e}")
                results[file_path] = 0
        
        total_records = sum(results.values())
        logger.info(f"Total records extracted: {total_records} from {len(results)} files")
        
        return results
    
    def get_unprocessed_count(self, assessment_type: Optional[str] = None) -> int:
        """
        Get count of unprocessed records in staging.
        
        Args:
            assessment_type: Optional filter by assessment type
            
        Returns:
            Number of unprocessed records
        """
        session = self.Session()
        
        try:
            if assessment_type:
                query = """
                    SELECT COUNT(*) FROM staging_raw_assessments
                    WHERE processed = FALSE AND assessment_type = :type
                """
                result = session.execute(query, {"type": assessment_type})
            else:
                query = "SELECT COUNT(*) FROM staging_raw_assessments WHERE processed = FALSE"
                result = session.execute(query)
            
            count = result.scalar()
            return count
            
        finally:
            session.close()


if __name__ == "__main__":
    # Example usage
    logging.basicConfig(level=logging.INFO)
    
    # Initialize extractor
    db_conn = "postgresql://analytics_user:analytics_pass@localhost:5432/people_analytics"
    extractor = CSVExtractor(db_conn)
    
    # Extract from sample CSV
    try:
        count = extractor.extract_from_csv(
            file_path="../data/sample_big_five.csv",
            assessment_type="BigFive"
        )
        print(f"✓ Extracted {count} records")
        
        # Check unprocessed
        unprocessed = extractor.get_unprocessed_count()
        print(f"Unprocessed records in staging: {unprocessed}")
        
    except FileNotFoundError:
        print("Sample CSV not found. Create sample data first.")
