# 📘 Runbook: People Analytics Data Platform

Operational guide for running the full data pipeline locally.

## Prerequisites

| Tool | Version | Check |
|---|---|---|
| Docker + Docker Compose | 20.10+ | `docker --version` |
| Python | 3.10+ | `python3 --version` |
| CMake | 3.14+ | `cmake --version` |
| g++ / build-essential | C++17 support | `g++ --version` |
| pip | 21+ | `pip --version` |

## Quick Start

```bash
# 1. Clone and enter the project
git clone https://github.com/Wjazz/people-analytics-data-platform.git
cd people-analytics-data-platform

# 2. Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Run the full demo
./run_demo.sh
```

## What `run_demo.sh` Does

1. **Starts PostgreSQL** via Docker Compose (port 5432)
2. **Activates Python venv**
3. **Runs `load_hr_data.py`** — injects `sample_hr.csv` and `sample_performance.csv` into `raw.*` schema
4. **Generates ephemeral dbt credentials** — `profiles.yml` created on-the-fly, never committed
5. **Runs `dbt deps` + `dbt run`** — installs dbt packages, materializes staging views and mart tables

## Running Tests

```bash
# Activate venv first
source .venv/bin/activate

# Run all unit tests
pytest tests/ -v

# Run only transformer tests
pytest tests/test_transformers.py -v

# Run only dbt structure tests
pytest tests/test_dbt_models.py -v
```

## Building the C++ Accelerator

```bash
cd c++-csv-accelerator
pip install pybind11

mkdir -p build && cd build
cmake ..
make

# Verify it works
cd ..
python -c "import sys; sys.path.insert(0,'build'); import csv_accel; print(csv_accel.read_csv('../data/sample_hr.csv')[0])"

# Run benchmark
python benchmark.py
```

## Troubleshooting

### Docker: port 5432 already in use
```bash
# Stop existing PostgreSQL
docker compose down -v
# Or kill the process using the port
sudo lsof -i :5432 | grep LISTEN
```

### dbt: "Could not find profile named 'people_analytics'"
The `profiles.yml` is generated at runtime by `run_demo.sh`. If running dbt manually:
```bash
cd dbt_project
cat << 'EOF' > profiles.yml
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
EOF
dbt run --profiles-dir .
```

### C++: "pybind11 not found"
```bash
pip install pybind11
# Then re-run cmake
cd c++-csv-accelerator/build
cmake .. && make
```
