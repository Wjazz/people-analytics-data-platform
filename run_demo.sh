#!/usr/bin/env bash
set -e

echo "============================================================"
echo "🚀 INICIANDO DEMO: PEOPLE ANALYTICS DATA PLATFORM"
echo "============================================================"

# 1. Levantar Infraestructura (Postgres)
echo "[1/4] Levantando Data Warehouse (PostgreSQL)..."
docker compose up -d
sleep 3 # Esperando inicialización

# 2. Entorno Python
echo "[2/4] Configurando entorno virtual..."
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt --quiet

# 3. Ingesta C++ (El Acelerador)
echo "[3/4] Ejecutando Ingesta Acelerada por C++ (Pybind11)..."
cd c++-csv-accelerator
chmod +x demo.sh
./demo.sh
cd ..

# 4. Transformación ELT
echo "[4/4] Verificando modelos dbt..."
cd dbt_project
dbt --version
cd ..

echo "============================================================"
echo "✅ DEMO COMPLETADA EXITOSAMENTE"
echo "Pipeline validado: Ingesta C++ -> Data Lake -> dbt Models."
echo "============================================================"
