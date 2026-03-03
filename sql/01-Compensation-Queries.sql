-- ===============================================
-- SQL para Análisis de Compensaciones
-- Base de datos de práctica para HR Analytics
-- ===============================================

-- ==================
-- CREACIÓN DE TABLAS
-- ==================

-- Tabla de empleados
CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE,
    department_id INTEGER,
    job_id INTEGER,
    manager_id INTEGER,
    status VARCHAR(20) -- 'Active', 'Terminated', 'On Leave'
);

-- Tabla de departamentos
CREATE TABLE departments (
    department_id INTEGER PRIMARY KEY,
    department_name VARCHAR(100),
    location VARCHAR(100)
);

-- Tabla de puestos (jobs)
CREATE TABLE jobs (
    job_id INTEGER PRIMARY KEY,
    job_title VARCHAR(100),
    job_family VARCHAR(50), -- 'Sales', 'Operations', 'Corporate', etc.
    job_level VARCHAR(20), -- 'Entry', 'Professional', 'Manager', 'Executive'
    hay_points INTEGER, -- Valorización Hay
    salary_band_id INTEGER
);

-- Tabla de bandas salariales
CREATE TABLE salary_bands (
    band_id INTEGER PRIMARY KEY,
    band_name VARCHAR(50),
    midpoint DECIMAL(10, 2),
    minimum DECIMAL(10, 2),
    maximum DECIMAL(10, 2),
    range_spread DECIMAL(5, 2), -- En porcentaje
    currency VARCHAR(3) DEFAULT 'PEN'
);

-- Tabla de salarios actuales
CREATE TABLE salaries (
    salary_id INTEGER PRIMARY KEY,
    employee_id INTEGER,
    effective_date DATE,
    base_salary DECIMAL(10, 2),
    salary_type VARCHAR(20), -- 'Monthly', 'Hourly'
    change_reason VARCHAR(50), -- 'Hire', 'Merit', 'Promotion', 'Market Adjustment'
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Tabla de incentivos
CREATE TABLE incentives (
    incentive_id INTEGER PRIMARY KEY,
    employee_id INTEGER,
    period VARCHAR(20), -- 'Q1-2024', 'Q2-2024', etc.
    oti_annual DECIMAL(10, 2), -- On-Target Incentive anual
    actual_payout DECIMAL(10, 2), -- Pago real
    payout_percentage DECIMAL(5, 2), -- % del OTI pagado
    payment_date DATE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Tabla de KPIs de incentivos
CREATE TABLE incentive_kpis (
    kpi_id INTEGER PRIMARY KEY,
    employee_id INTEGER,
    period VARCHAR(20),
    kpi_name VARCHAR(50), -- 'Sales', 'Margin', 'NPS', etc.
    target_value DECIMAL(10, 2),
    actual_value DECIMAL(10, 2),
    achievement_pct DECIMAL(5, 2),
    weight DECIMAL(5, 2), -- Peso en el esquema
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Tabla de datos de mercado (benchmark)
CREATE TABLE market_data (
    market_id INTEGER PRIMARY KEY,
    job_title VARCHAR(100),
    source VARCHAR(50), -- 'Mercer', 'Willis Towers Watson', etc.
    survey_year INTEGER,
    percentile_25 DECIMAL(10, 2),
    percentile_50 DECIMAL(10, 2),
    percentile_75 DECIMAL(10, 2),
    sample_size INTEGER
);

-- ==================
-- INSERCIÓN DE DATOS DE EJEMPLO
-- ==================

-- Departamentos
INSERT INTO departments VALUES
(1, 'Ventas', 'Lima'),
(2, 'Operaciones', 'Lima'),
(3, 'Recursos Humanos', 'Lima'),
(4, 'Finanzas', 'Lima'),
(5, 'Tecnología', 'Lima');

-- Bandas salariales
INSERT INTO salary_bands VALUES
(1, 'Banda 1 - Entry', 4500, 3500, 5500, 57.14, 'PEN'),
(2, 'Banda 2 - Professional', 6000, 4500, 7500, 66.67, 'PEN'),
(3, 'Banda 3 - Senior', 8000, 6000, 10000, 66.67, 'PEN'),
(4, 'Banda 4 - Manager', 12000, 9000, 15000, 66.67, 'PEN'),
(5, 'Banda 5 - Senior Manager', 18000, 13500, 22500, 66.67, 'PEN');

-- Jobs
INSERT INTO jobs VALUES
(1, 'Vendedor', 'Sales', 'Entry', 250, 1),
(2, 'Vendedor Senior', 'Sales', 'Professional', 350, 2),
(3, 'Jefe de Ventas', 'Sales', 'Manager', 550, 4),
(4, 'Analista de Compensaciones', 'HR', 'Professional', 400, 2),
(5, 'Gerente de Compensaciones', 'HR', 'Manager', 650, 4),
(6, 'Analista de Operaciones', 'Operations', 'Professional', 380, 2);

-- Empleados (30 empleados de ejemplo)
INSERT INTO employees VALUES
(1, 'Juan', 'Pérez', 'jperez@empresa.com', '2020-01-15', 1, 2, 3, 'Active'),
(2, 'María', 'García', 'mgarcia@empresa.com', '2019-06-20', 1, 2, 3, 'Active'),
(3, 'Carlos', 'López', 'clopez@empresa.com', '2018-03-10', 1, 3, NULL, 'Active'),
(4, 'Ana', 'Martínez', 'amartinez@empresa.com', '2021-07-01', 3, 4, 5, 'Active'),
(5, 'Luis', 'Rodríguez', 'lrodriguez@empresa.com', '2017-11-15', 3, 5, NULL, 'Active'),
(6, 'Elena', 'Fernández', 'efernandez@empresa.com', '2022-02-20', 1, 1, 3, 'Active'),
(7, 'Pedro', 'Sánchez', 'psanchez@empresa.com', '2020-09-05', 2, 6, NULL, 'Active'),
(8, 'Laura', 'Gómez', 'lgomez@empresa.com', '2019-12-12', 1, 2, 3, 'Active'),
(9, 'Diego', 'Torres', 'dtorres@empresa.com', '2021-04-18', 1, 1, 3, 'Active'),
(10, 'Carmen', 'Ruiz', 'cruiz@empresa.com', '2018-08-22', 2, 6, NULL, 'Active');

-- Salarios actuales
INSERT INTO salaries VALUES
(1, 1, '2023-01-01', 6200, 'Monthly', 'Merit'),
(2, 2, '2023-01-01', 6800, 'Monthly', 'Merit'),
(3, 3, '2023-01-01', 13500, 'Monthly', 'Promotion'),
(4, 4, '2023-01-01', 5400, 'Monthly', 'Merit'),
(5, 5, '2023-01-01', 16000, 'Monthly', 'Merit'),
(6, 6, '2023-01-01', 3800, 'Monthly', 'Hire'),
(7, 7, '2023-01-01', 6100, 'Monthly', 'Merit'),
(8, 8, '2023-01-01', 5900, 'Monthly', 'Merit'),
(9, 9, '2023-01-01', 3600, 'Monthly', 'Hire'),
(10, 10, '2023-01-01', 6300, 'Monthly', 'Merit');

-- Datos de mercado
INSERT INTO market_data VALUES
(1, 'Analista de Compensaciones', 'Mercer', 2023, 5000, 6200, 7500, 45),
(2, 'Vendedor Senior', 'Mercer', 2023, 5500, 6500, 7800, 120),
(3, 'Gerente de Compensaciones', 'Mercer', 2023, 14000, 17000, 20000, 28),
(4, 'Jefe de Ventas', 'Mercer', 2023, 11000, 13000, 15500, 67);

-- ==================
-- CONSULTAS BÁSICAS
-- ==================

-- 1. Lista de empleados con su salario actual
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name,
    j.job_title,
    d.department_name,
    s.base_salary
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
JOIN departments d ON e.department_id = d.department_id
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
AND e.status = 'Active';

-- ==================
-- ANÁLISIS DE COMPENSACIONES
-- ==================

-- 2. Cálculo de Compa-Ratio por empleado
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    j.job_title,
    s.base_salary AS current_salary,
    sb.midpoint AS band_midpoint,
    ROUND((s.base_salary / sb.midpoint) * 100, 2) AS compa_ratio,
    CASE 
        WHEN (s.base_salary / sb.midpoint) * 100 < 80 THEN 'Muy por debajo'
        WHEN (s.base_salary / sb.midpoint) * 100 < 90 THEN 'Debajo de mercado'
        WHEN (s.base_salary / sb.midpoint) * 100 <= 110 THEN 'En línea'
        WHEN (s.base_salary / sb.midpoint) * 100 <= 120 THEN 'Por encima'
        ELSE 'Muy por encima'
    END AS position_status
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
JOIN salary_bands sb ON j.salary_band_id = sb.band_id
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
AND e.status = 'Active'
ORDER BY compa_ratio;

-- 3. Cálculo de Range Penetration
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    j.job_title,
    s.base_salary,
    sb.minimum,
    sb.maximum,
    ROUND(
        ((s.base_salary - sb.minimum) / (sb.maximum - sb.minimum)) * 100, 
        2
    ) AS range_penetration,
    CASE 
        WHEN ((s.base_salary - sb.minimum) / (sb.maximum - sb.minimum)) * 100 < 25 THEN 'Q1 - Nuevo'
        WHEN ((s.base_salary - sb.minimum) / (sb.maximum - sb.minimum)) * 100 < 50 THEN 'Q2 - En desarrollo'
        WHEN ((s.base_salary - sb.minimum) / (sb.maximum - sb.minimum)) * 100 < 75 THEN 'Q3 - Competente'
        ELSE 'Q4 - Experto'
    END AS quartile
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
JOIN salary_bands sb ON j.salary_band_id = sb.band_id
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
AND e.status = 'Active'
ORDER BY range_penetration;

-- 4. Comparación con mercado
SELECT 
    j.job_title,
    COUNT(DISTINCT e.employee_id) AS num_employees,
    ROUND(AVG(s.base_salary), 2) AS avg_internal_salary,
    m.percentile_50 AS market_p50,
    ROUND(
        ((AVG(s.base_salary) - m.percentile_50) / m.percentile_50) * 100,
        2
    ) AS variance_from_market_pct,
    CASE 
        WHEN ((AVG(s.base_salary) - m.percentile_50) / m.percentile_50) * 100 < -10 THEN 'Por debajo de mercado'
        WHEN ((AVG(s.base_salary) - m.percentile_50) / m.percentile_50) * 100 <= 10 THEN 'En línea con mercado'
        ELSE 'Por encima de mercado'
    END AS market_position
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
LEFT JOIN market_data m ON j.job_title = m.job_title AND m.survey_year = 2023
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
AND e.status = 'Active'
AND m.market_id IS NOT NULL
GROUP BY j.job_title, m.percentile_50
ORDER BY variance_from_market_pct;

-- 5. Análisis de equidad salarial por departamento
SELECT 
    d.department_name,
    j.job_level,
    COUNT(*) AS num_employees,
    ROUND(AVG(s.base_salary), 2) AS avg_salary,
    ROUND(MIN(s.base_salary), 2) AS min_salary,
    ROUND(MAX(s.base_salary), 2) AS max_salary,
    ROUND(STDDEV(s.base_salary), 2) AS std_dev,
    ROUND(
        (STDDEV(s.base_salary) / AVG(s.base_salary)) * 100,
        2
    ) AS coefficient_variation
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
JOIN departments d ON e.department_id = d.department_id
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
AND e.status = 'Active'
GROUP BY d.department_name, j.job_level
HAVING COUNT(*) >= 2
ORDER BY d.department_name, j.job_level;

-- 6. Budget planning - Cálculo de masa salarial
SELECT 
    d.department_name,
    COUNT(DISTINCT e.employee_id) AS headcount,
    ROUND(SUM(s.base_salary), 2) AS monthly_payroll,
    ROUND(SUM(s.base_salary) * 12, 2) AS annual_payroll,
    ROUND(AVG(s.base_salary), 2) AS avg_salary
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN departments d ON e.department_id = d.department_id
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
AND e.status = 'Active'
GROUP BY d.department_name
ORDER BY annual_payroll DESC;

-- 7. Identificar candidatos para ajuste salarial
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    j.job_title,
    s.base_salary,
    sb.midpoint,
    ROUND((s.base_salary / sb.midpoint) * 100, 2) AS compa_ratio,
    ROUND(((sb.midpoint * 0.90) - s.base_salary), 2) AS gap_to_90_pct,
    DATEDIFF('day', e.hire_date, CURRENT_DATE) / 365.25 AS tenure_years
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN jobs j ON e.job_id = j.job_id
JOIN salary_bands sb ON j.salary_band_id = sb.band_id
WHERE s.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE employee_id = e.employee_id
)
AND e.status = 'Active'
AND (s.base_salary / sb.midpoint) * 100 < 90  -- Compa-ratio < 90%
AND DATEDIFF('day', e.hire_date, CURRENT_DATE) / 365.25 > 1  -- Más de 1 año
ORDER BY compa_ratio;

-- ==================
-- EJERCICIOS PRÁCTICOS
-- ==================

-- EJERCICIO 1: 
-- Calcula el compa-ratio promedio por nivel de puesto (job_level)

-- EJERCICIO 2:
-- Encuentra los 5 empleados con mayor brecha respecto al mercado

-- EJERCICIO 3:
-- Calcula cuánto costaría llevar a todos los empleados con compa-ratio < 90%
-- a un compa-ratio de 95%

-- EJERCICIO 4:
-- Determina el presupuesto necesario para un incremento promedio del 5%
-- para todos los empleados activos

-- EJERCICIO 5:
-- Identifica puestos donde la variación salarial interna (std dev) sea > 15%
-- del promedio (posible problema de equidad)
