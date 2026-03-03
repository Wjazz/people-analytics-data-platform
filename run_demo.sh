#!/usr/bin/env bash
set -e

echo "============================================================"
echo "🚀 INICIANDO DEMO: PEOPLE ANALYTICS DATA PLATFORM"
echo "============================================================"

# 1. Levantar Infraestructura
echo "[1/4] Limpiando entorno y levantando Data Warehouse (PostgreSQL)..."
docker compose down -v 2>/dev/null
docker compose up -d
sleep 5 # Tiempo extra para que Postgres exponga el puerto TCP

# 2. Entorno Python
echo "[2/4] Activando entorno virtual..."
source .venv/bin/activate

# 3. Ejecución del Extractor
echo "[3/4] Ejecutando Extracción y Limpieza..."
python src/extractors/csv_extractor.py

# 4. Transformación ELT con dbt
echo "[4/4] Ejecutando Modelado de Datos (dbt)..."
cd dbt_project
dbt deps --profiles-dir .
dbt run --profiles-dir .
cd ..

echo "============================================================"
echo "✅ DEMO FINALIZADA CON ÉXITO."
echo "Pipeline validado: CSV -> PostgreSQL -> dbt Models."
echo "============================================================"
