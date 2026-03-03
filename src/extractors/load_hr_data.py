import pandas as pd
from sqlalchemy import create_engine, text
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

db_url = "postgresql://analytics_user:analytics_pass@localhost:5432/people_analytics"
engine = create_engine(db_url)

def load_data():
    try:
        # 1. Crear el esquema 'raw'
        with engine.connect() as conn:
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
            conn.commit()
            logger.info("Esquema 'raw' verificado.")

        # 2. Inyectar Empleados
        df_emp = pd.read_csv("data/sample_hr.csv")
        df_emp.to_sql("employees", engine, schema="raw", if_exists="replace", index=False)
        logger.info(f"✅ {len(df_emp)} registros en raw.employees")

        # 3. Inyectar Evaluaciones de Desempeño
        df_perf = pd.read_csv("data/sample_performance.csv")
        df_perf.to_sql("performance_reviews", engine, schema="raw", if_exists="replace", index=False)
        logger.info(f"✅ {len(df_perf)} registros en raw.performance_reviews")

    except Exception as e:
        logger.error(f"Error fatal en la inyección: {e}")

if __name__ == "__main__":
    load_data()
