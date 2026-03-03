import pandas as pd
from sqlalchemy import create_engine, text
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

db_url = "postgresql://analytics_user:analytics_pass@localhost:5432/people_analytics"
engine = create_engine(db_url)

def load_data():
    try:
        # 1. Crear el esquema 'raw' que dbt está buscando
        with engine.connect() as conn:
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
            conn.commit()
            logger.info("Esquema 'raw' verificado.")

        # 2. Leer la "sangre" (datos HR)
        df = pd.read_csv("data/sample_hr.csv")
        
        # 3. Inyectar directamente a la tabla raw.employees
        df.to_sql("employees", engine, schema="raw", if_exists="replace", index=False)
        logger.info(f"✅ {len(df)} registros inyectados exitosamente en raw.employees")
        
    except Exception as e:
        logger.error(f"Error fatal en la inyección: {e}")

if __name__ == "__main__":
    load_data()
