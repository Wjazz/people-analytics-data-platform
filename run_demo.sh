#!/usr/bin/env bash
set -e

echo "============================================================"
echo "🚀 INICIANDO DEMO: PEOPLE ANALYTICS DATA PLATFORM"
echo "============================================================"

# 1. Levantar Infraestructura
echo "[1/4] Levantando Data Warehouse (PostgreSQL)..."
docker compose down -v 2>/dev/null
docker compose up -d
sleep 5

# 2. Entorno Python
echo "[2/4] Activando entorno virtual..."
source .venv/bin/activate

# 3. Ejecución del Extractor
echo "[3/4] Ejecutando Inyección de Datos Raw..."
python src/extractors/load_hr_data.py

# 4. Generación segura de credenciales temporales para DBT
echo "[4/4] Ejecutando Modelado de Datos (dbt)..."
cd dbt_project

# Recrea el archivo localmente solo para la ejecución, sin subirlo a Git
cat << 'INNER_EOF' > profiles.yml
people_analytics:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: analytics_user
      pass: analytics_pass
      port: 5432
      dbname: people_analytics
      schema: analytics_marts
      threads: 4
INNER_EOF

dbt deps --profiles-dir .
dbt run --profiles-dir .
cd ..

echo "============================================================"
echo "✅ DEMO FINALIZADA CON ÉXITO."
echo "Pipeline validado. Las credenciales de dbt se generaron al vuelo y no se rastrean en Git."
echo "============================================================"
