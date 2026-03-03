# 📊 SQL para HR Analytics

Colección de queries SQL para análisis de compensación y People Analytics.

## 🎯 Contenido

- **Base de datos de práctica** con esquema completo de RRHH
- **15+ queries** de análisis de compensación
- **Ejercicios prácticos** con soluciones

## 🗄️ Estructura de la Base de Datos

### Tablas Principales

- `employees` - Información de empleados
- `salaries` - Historial de salarios
- `jobs` - Puestos y valorización
- `salary_bands` - Bandas salariales
- `departments` - Departamentos
- `incentives` - Pagos variables
- `incentive_kpis` - KPIs de incentivos
- `market_data` - Datos de mercado (benchmarking)

## 🚀 Setup Rápido

### SQLite (recomendado para práctica)

```bash
sqlite3 hr_compensation.db < 01-Compensation-Queries.sql
```

### PostgreSQL

```bash
createdb hr_compensation
psql hr_compensation < 01-Compensation-Queries.sql
```

## 📊 Queries Incluidas

### Análisis de Compensación

1. **Lista de empleados con salario actual**
2. **Cálculo de Compa-Ratio** - Identifica posición vs midpoint
3. **Range Penetration** - Clasifica por cuartil (Q1-Q4)
4. **Comparación con mercado** - Identifica brechas vs benchmarks
5. **Análisis de equidad salarial** - Varianza por departamento/nivel
6. **Budget planning** - Masa salarial por área
7. **Candidatos para ajuste** - Empleados con compa-ratio < 90%

### Ejemplos de Uso

```sql
-- Compa-Ratio por empleado
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    j.job_title,
    s.base_salary,
    sb.midpoint,
    ROUND((s.base_salary / sb.midpoint) * 100, 2) AS compa_ratio
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
JOIN salary_bands sb ON j.salary_band_id = sb.band_id
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
ORDER BY compa_ratio;
```

## 🎓 Ejercicios Prácticos

**Ver final de `01-Compensation-Queries.sql`**

1. ✏️ Calcular compa-ratio promedio por nivel de puesto
2. ✏️ Encontrar top 5 empleados con mayor brecha vs mercado
3. ✏️ Calcular presupuesto para llevar compa-ratio < 90% a 95%
4. ✏️ Determinar budget para incremento del 5%
5. ✏️ Identificar puestos con alta variación salarial (>15%)

## 📚 Aplicaciones

### Para Entrevistas

**Pregunta:** "¿Cómo analizarías equidad salarial con SQL?"

**Respuesta:**
```sql
"Usaría una query que compare salarios controlando por puesto y nivel:

SELECT 
    j.job_title,
    COUNT(*) AS employees,
    AVG(s.base_salary) AS avg_salary,
    STDDEV(s.base_salary) / AVG(s.base_salary) * 100 AS coef_variation
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
GROUP BY j.job_title
HAVING COUNT(*) >= 3
    AND STDDEV(s.base_salary) / AVG(s.base_salary) * 100 > 15
"
```

### Para Reportes

- Extracción mensual de masa salarial
- Listas para ciclo de merit increase
- Análisis de competitividad vs mercado
- Identificación de outliers salariales

## 🛠️ Stack Tecnológico

- **SQL:** PostgreSQL, SQLite
- **Conectores:** psycopg2 (Python), DBeaver, pgAdmin
- **Integración:** Pandas (pd.read_sql), Excel (Power Query)

## 📖 Documentación Adicional

- [01-Compensation-Queries.sql](./01-Compensation-Queries.sql) - Script completo con datos
- [SETUP.md](../SETUP.md) - Instrucciones de instalación

## 💡 Tips

**Optimización de queries:**
- Usa índices en `employee_id`, `effective_date`
- Subconsulta `MAX(effective_date)` es común - considera CREATE VIEW
- Para análisis históricos, usa window functions

**Mejores prácticas:**
- Siempre filtrar por `effective_date` más reciente
- Verificar empleados activos (`status = 'Active'`)
- Documentar unidades monetarias (PEN, USD, etc.)

## 🎯 Aplicaciones en Trabajo Real

| Caso de Uso | Query Relacionada |
|-------------|-------------------|
| Ciclo de merit increase | Compa-ratio + Range Penetration |
| Propuesta de promoción | Comparación con banda destino |
| Análisis de equidad | Varianza por departamento/género |
| Budget planning | Masa salarial + Proyecciones |
| Benchmarking | Comparación con market_data |

---

**Autor:** James  
**Especialización:** Compensation Analytics & People Analytics  
**Stack:** SQL, Python, Excel
