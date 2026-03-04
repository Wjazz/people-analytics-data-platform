<div align="center">
  
# ⚙️ People Analytics Data Platform
*Arquitectura de Datos Industrial para Recursos Humanos y Psicometría*

<img src="https://img.shields.io/badge/Status-Mission_Ready-FFD700?style=for-the-badge&logo=rocket&logoColor=121212" />
<img src="https://img.shields.io/badge/Data_Flow-Optimized-00E5FF?style=for-the-badge&logo=apacheairflow&logoColor=121212" />
<img src="https://img.shields.io/badge/Performance-2.9x_Faster-FF1744?style=for-the-badge&logo=c%2B%2B&logoColor=E0E0E0" />

</div>

---

### 🎯 Visión General para Reclutadores Técnicos / Tech Leads

Este repositorio no es un tutorial; es un **Data Pipeline completo e idempotente** diseñado para ingerir, transformar y modelar datos complejos de Recursos Humanos (Riesgo de Rotación, Evaluaciones de Desempeño y Perfiles Psicométricos). 

Resuelve un problema clásico de la ingeniería de datos: **El cuello de botella del GIL de Python** durante la ingesta de archivos masivos, combinándolo con las mejores prácticas modernas de transformación en SQL.

### ⚡ El Valor Técnico (¿Por qué este repo es diferente?)

1. **Ingesta Acelerada en C++ (`pybind11`):** En lugar de depender exclusivamente de Pandas, desarrollé un acelerador nativo en C++17 para la lectura y parseo de CSVs, logrando un rendimiento **~2.9x superior** frente a las librerías estándar (0.039s vs 0.113s en benchmarks locales).
2. **Transformación ELT (Data Build Tool - dbt):** Uso de `dbt` para el modelado dimensional dentro del Data Warehouse. Incluye *Window Functions* para cálculo de percentiles de desempeño, ofuscación de PII (MD5 Hashing para cumplir normativas de privacidad) y materialización de vistas/tablas.
3. **Reproducibilidad Inmaculada:** Entorno completamente dockerizado (PostgreSQL) con orquestación Bash de 1-clic y pruebas de Integración Continua (CI) mediante GitHub Actions.

---

### 🚀 Prueba de 1-Clic (One-Click Demo)

¿Tienes 3 minutos? Puedes reproducir este pipeline completo en tu máquina local. El script levantará la base de datos, compilará el código C++, generará credenciales efímeras seguras, inyectará datos sintéticos y ejecutará el modelado dbt.

**Requisitos mínimos:** `Docker`, `Python 3.10+`, `CMake`, `build-essential`.

```bash
# 1. Clonar el repositorio
git clone [https://github.com/Wjazz/people-analytics-data-platform.git](https://github.com/Wjazz/people-analytics-data-platform.git)
cd people-analytics-data-platform

# 2. Ejecutar la demo completa
./run_demo.sh
