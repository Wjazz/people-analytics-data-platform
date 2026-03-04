# People Analytics Data Platform ⚙️📊

[![CI](https://github.com/Wjazz/people-analytics-data-platform/actions/workflows/ci-pipeline.yml/badge.svg)](https://github.com/Wjazz/people-analytics-data-platform/actions)

Plataforma de Ingeniería de Datos diseñada para extraer, transformar y modelar datos complejos de Recursos Humanos (People Analytics y Riesgo Organizacional).

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA SOURCES                             │
│   sample_hr.csv  ·  sample_performance.csv  ·  big_five    │
└──────────┬──────────────────────────────┬───────────────────┘
           │                              │
           ▼                              ▼
┌──────────────────┐          ┌───────────────────────┐
│  Python Loader   │          │  C++ CSV Accelerator  │
│  (pandas + SQL   │          │  (pybind11, ~2.9x     │
│   Alchemy)       │          │   faster ingestion)   │
└────────┬─────────┘          └──────────┬────────────┘
         │                               │
         ▼                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  PostgreSQL (Docker)                         │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │ raw.*    │───▶│ staging.*    │───▶│ analytics_marts.*│  │
│  │(landing) │    │(PII hashing, │    │(PERCENT_RANK,    │  │
│  │          │    │ cleaning)    │    │ z-scores, tiers) │  │
│  └──────────┘    └──────────────┘    └──────────────────┘  │
│                        dbt                                  │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│            CI/CD (GitHub Actions)                            │
│  pytest → load_hr_data.py → dbt run → dbt test             │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Core Features

* **C++ CSV Accelerator (pybind11):** Native C++17 module for high-speed CSV ingestion, bypassing Python's GIL.
* **ELT Transformation (dbt):** Dimensional modeling in-database — MD5 PII hashing, window functions, z-score outlier detection.
* **Star Schema Warehouse:** PostgreSQL with dimension/fact tables for psychometric assessments (Big Five, PsyCap, Holland, Dark Tetrad).
* **Automated CI/CD:** Full E2E pipeline validation on every push (pytest → extraction → dbt run + test).
* **GCP Infrastructure (Terraform):** Cloud SQL + Artifact Registry + Cloud Run v2, production-ready.

## ⚡ Quick Demo (1-Click Reproducibility)

```bash
git clone https://github.com/Wjazz/people-analytics-data-platform.git
cd people-analytics-data-platform
./run_demo.sh
```

**Requirements:** Docker, Python 3.10+, CMake, build-essential.
See [docs/runbook.md](docs/runbook.md) for detailed setup instructions.

## 📁 Project Structure

```
├── c++-csv-accelerator/     # Native C++17 CSV parser (pybind11)
│   ├── src/csv_accel.cpp    #   Core parser + pybind11 bindings
│   ├── CMakeLists.txt       #   Build configuration
│   ├── benchmark.py         #   Performance comparison script
│   └── BENCHMARK.md         #   Reproducible benchmark results
├── data/                    # Sample datasets (HR, performance, Big Five)
├── dbt_project/             # dbt models (staging → marts)
│   ├── models/staging/      #   PII hashing, cleaning, normalization
│   └── models/marts/        #   Performance percentiles, analytics
├── sql/                     # Raw SQL (star schema DDL, compensation queries)
├── src/
│   ├── extractors/          # CSV → PostgreSQL loaders
│   └── transformers/        # BigFiveNormalizer, PsyCapCalculator
├── dags/                    # Apache Airflow DAG (psychometric ETL)
├── terraform/               # GCP infrastructure (Cloud SQL, Cloud Run)
├── tests/                   # pytest suite (data, transformers, dbt)
├── docs/                    # Operational documentation
├── docker-compose.yml       # Local dev environment
└── run_demo.sh              # One-click demo script
```

## 🧪 Running Tests

```bash
# Unit tests (no database required)
pytest tests/ -v

# Full E2E (requires Docker + PostgreSQL)
./run_demo.sh
```

## 📄 License

This project is for educational and portfolio purposes.
