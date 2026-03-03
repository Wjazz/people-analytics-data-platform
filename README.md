# People Analytics Data Platform ⚙️📊

Una plataforma de ingeniería de datos construida para procesar, transformar y modelar métricas complejas de Recursos Humanos (People Analytics y Riesgo Organizacional).

## 🚀 Arquitectura y Stack Tecnológico
* **Ingesta Acelerada:** `C++17` y `Pybind11` (Superando las limitaciones del GIL de Python para procesar CSVs masivos).
* **Transformación (ELT):** `dbt` (Data Build Tool) para modelado dimensional en base de datos.
* **Almacenamiento (Data Lake/Warehouse):** `PostgreSQL` (Dockerizado).
* **Orquestación:** Preparado para `Apache Airflow`.

## ⚡ Quick Demo (Reproducibilidad en 1-clic)
Para evaluar el pipeline completo localmente (Ingesta C++ -> PostgreSQL -> dbt Models), clona el repositorio y ejecuta:

```bash
./run_demo.sh
