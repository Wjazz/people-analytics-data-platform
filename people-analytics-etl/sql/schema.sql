-- People Analytics Data Warehouse Schema
-- Database: people_analytics
-- Purpose: Psychometric assessments, employee data, and analytics

-- =============================================================================
-- DIMENSION TABLES
-- =============================================================================

-- Dimension: Employee
CREATE TABLE IF NOT EXISTS dim_employee (
    employee_id SERIAL PRIMARY KEY,
    employee_code VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hire_date DATE NOT NULL,
    termination_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    department_id INTEGER,
    position_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_employee_code ON dim_employee(employee_code);
CREATE INDEX idx_employee_active ON dim_employee(is_active);
CREATE INDEX idx_employee_department ON dim_employee(department_id);

-- Dimension: Department
CREATE TABLE IF NOT EXISTS dim_department (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    department_code VARCHAR(20) UNIQUE NOT NULL,
    parent_department_id INTEGER,
    cost_center VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: Position/Job Title
CREATE TABLE IF NOT EXISTS dim_position (
    position_id SERIAL PRIMARY KEY,
    position_title VARCHAR(100) NOT NULL,
    position_code VARCHAR(20) UNIQUE NOT NULL,
    position_level INTEGER, -- 1=Junior, 2=Mid, 3=Senior, 4=Lead, 5=Manager
    salary_band_min DECIMAL(10,2),
    salary_band_max DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: Date (for time-series analysis)
CREATE TABLE IF NOT EXISTS dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INTEGER NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_date_full ON dim_date(full_date);
CREATE INDEX idx_date_year_month ON dim_date(year, month);

-- =============================================================================
-- FACT TABLES
-- =============================================================================

-- Fact: Big Five Personality Assessment
CREATE TABLE IF NOT EXISTS fact_big_five_assessment (
    assessment_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES dim_employee(employee_id),
    assessment_date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    
    -- Neuroticism (Estabilidad Emocional - reverse scored)
    neuroticism_raw_score DECIMAL(5,2),
    neuroticism_t_score DECIMAL(5,2), -- T-score (M=50, SD=10)
    neuroticism_percentile INTEGER,
    
    -- Extraversion
    extraversion_raw_score DECIMAL(5,2),
    extraversion_t_score DECIMAL(5,2),
    extraversion_percentile INTEGER,
    
    -- Openness (Apertura Mental)
    openness_raw_score DECIMAL(5,2),
    openness_t_score DECIMAL(5,2),
    openness_percentile INTEGER,
    
    -- Agreeableness (Amabilidad)
    agreeableness_raw_score DECIMAL(5,2),
    agreeableness_t_score DECIMAL(5,2),
    agreeableness_percentile INTEGER,
    
    -- Conscientiousness (Tesón)
    conscientiousness_raw_score DECIMAL(5,2),
    conscientiousness_t_score DECIMAL(5,2),
    conscientiousness_percentile INTEGER,
    
    -- Metadata
    assessment_version VARCHAR(20), -- e.g., "NEO-FFI", "BFI-44"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bigfive_employee ON fact_big_five_assessment(employee_id);
CREATE INDEX idx_bigfive_date ON fact_big_five_assessment(assessment_date_id);

-- Fact: Dark Tetrad Assessment (Machiavellianism, Narcissism, Psychopathy, Sadism)
CREATE TABLE IF NOT EXISTS fact_dark_tetrad_assessment (
    assessment_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES dim_employee(employee_id),
    assessment_date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    
    -- Machiavellianism
    machiavellianism_raw_score DECIMAL(5,2),
    machiavellianism_standardized DECIMAL(5,2), -- 0-50 scale
    
    -- Narcissism
    narcissism_raw_score DECIMAL(5,2),
    narcissism_standardized DECIMAL(5,2),
    
    -- Psychopathy
    psychopathy_raw_score DECIMAL(5,2),
    psychopathy_standardized DECIMAL(5,2),
    
    -- Sadism
    sadism_raw_score DECIMAL(5,2),
    sadism_standardized DECIMAL(5,2),
    
    -- Composite Dark Tetrad Score
    dark_tetrad_composite DECIMAL(5,2),
    
    -- Assessment metadata
    assessment_version VARCHAR(20), -- e.g., "SD4", "Short Dark Triad"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_darktetrad_employee ON fact_dark_tetrad_assessment(employee_id);
CREATE INDEX idx_darktetrad_date ON fact_dark_tetrad_assessment(assessment_date_id);

-- Fact: Holland Code (RIASEC) Assessment
CREATE TABLE IF NOT EXISTS fact_holland_assessment (
    assessment_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES dim_employee(employee_id),
    assessment_date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    
    -- RIASEC scores
    realistic_score DECIMAL(5,2),
    investigative_score DECIMAL(5,2),
    artistic_score DECIMAL(5,2),
    social_score DECIMAL(5,2),
    enterprising_score DECIMAL(5,2),
    conventional_score DECIMAL(5,2),
    
    -- Holland Code (top 3 letters, e.g., "IAC", "SEC")
    holland_code_primary CHAR(1),
    holland_code_secondary CHAR(1),
    holland_code_tertiary CHAR(1),
    holland_code_full VARCHAR(6), -- All 6 letters ranked
    
    -- Metadata
    assessment_version VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_holland_employee ON fact_holland_assessment(employee_id);
CREATE INDEX idx_holland_code ON fact_holland_assessment(holland_code_primary, holland_code_secondary);

-- Fact: Psychological Capital (PsyCap) - Hope, Self-Efficacy, Resilience, Optimism
CREATE TABLE IF NOT EXISTS fact_psycap_assessment (
    assessment_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES dim_employee(employee_id),
    assessment_date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    
    -- PsyCap Dimensions (1-6 scale typically)
    hope_score DECIMAL(5,2),
    self_efficacy_score DECIMAL(5,2),
    resilience_score DECIMAL(5,2),
    optimism_score DECIMAL(5,2),
    
    -- Composite PsyCap Score
    psycap_composite DECIMAL(5,2),
    psycap_category VARCHAR(20), -- "Low", "Medium", "High"
    
    -- Metadata
    assessment_version VARCHAR(20), -- e.g., "CPC-12R", "PCQ-24"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_psycap_employee ON fact_psycap_assessment(employee_id);
CREATE INDEX idx_psycap_composite ON fact_psycap_assessment(psycap_composite);

-- Fact: Employee Performance
CREATE TABLE IF NOT EXISTS fact_performance (
    performance_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES dim_employee(employee_id),
    review_date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    
    -- Performance metrics
    overall_rating DECIMAL(3,2), -- e.g., 1.0 to 5.0
    technical_skills_rating DECIMAL(3,2),
    soft_skills_rating DECIMAL(3,2),
    goal_achievement_percentage DECIMAL(5,2),
    
    -- Flags
    is_promotion_eligible BOOLEAN DEFAULT FALSE,
    is_pip BOOLEAN DEFAULT FALSE, -- Performance Improvement Plan
    
    -- Metadata
    reviewer_employee_id INTEGER REFERENCES dim_employee(employee_id),
    review_period VARCHAR(20), -- e.g., "2024-Q4", "2025-H1"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_performance_employee ON fact_performance(employee_id);
CREATE INDEX idx_performance_rating ON fact_performance(overall_rating);

-- Fact: Turnover/Separation
CREATE TABLE IF NOT EXISTS fact_turnover (
    turnover_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES dim_employee(employee_id),
    separation_date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    
    -- Turnover details
    turnover_type VARCHAR(20), -- "Voluntary", "Involuntary", "Retirement"
    separation_reason VARCHAR(100),
    tenure_days INTEGER,
    tenure_months DECIMAL(5,2),
    
    -- Exit interview data
    would_rehire BOOLEAN,
    exit_satisfaction_score DECIMAL(3,2), -- 1-5
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_turnover_employee ON fact_turnover(employee_id);
CREATE INDEX idx_turnover_type ON fact_turnover(turnover_type);

-- Fact: Recruitment Cost & Metrics
CREATE TABLE IF NOT EXISTS fact_recruitment (
    recruitment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES dim_employee(employee_id), -- NULL if not hired
    position_id INTEGER NOT NULL REFERENCES dim_position(position_id),
    posting_date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    hire_date_id INTEGER REFERENCES dim_date(date_id),
    
    -- Recruitment metrics
    applicants_count INTEGER,
    interviews_count INTEGER,
    time_to_hire_days INTEGER,
    cost_per_hire DECIMAL(10,2),
    source VARCHAR(50), -- "LinkedIn", "Referral", "Indeed", etc.
    
    -- Outcome
    was_hired BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recruitment_position ON fact_recruitment(position_id);
CREATE INDEX idx_recruitment_hired ON fact_recruitment(was_hired);

-- =============================================================================
-- STAGING TABLES (For ETL intermediate data)
-- =============================================================================

CREATE TABLE IF NOT EXISTS staging_raw_assessments (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(50),
    assessment_type VARCHAR(50), -- "BigFive", "DarkTetrad", "Holland", "PsyCap"
    assessment_date DATE,
    raw_data JSONB, -- Store all assessment responses as JSON
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_staging_processed ON staging_raw_assessments(processed);
CREATE INDEX idx_staging_type ON staging_raw_assessments(assessment_type);

-- =============================================================================
-- ANALYTICS VIEWS
-- =============================================================================

-- View: Employee with Latest Psychometric Profile
CREATE OR REPLACE VIEW view_employee_psychometric_profile AS
SELECT 
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    d.department_name,
    p.position_title,
    
    -- Latest Big Five
    bf.extraversion_t_score,
    bf.agreeableness_t_score,
    bf.conscientiousness_t_score,
    bf.neuroticism_t_score,
    bf.openness_t_score,
    
    -- Latest Dark Tetrad
    dt.machiavellianism_standardized,
    dt.narcissism_standardized,
    dt.psychopathy_standardized,
    dt.sadism_standardized,
    
    -- Latest Holland Code
    h.holland_code_primary,
    h.holland_code_secondary,
    h.holland_code_tertiary,
    
    -- Latest PsyCap
    pc.psycap_composite,
    pc.hope_score,
    pc.self_efficacy_score,
    pc.resilience_score,
    pc.optimism_score
    
FROM dim_employee e
LEFT JOIN dim_department d ON e.department_id = d.department_id
LEFT JOIN dim_position p ON e.position_id = p.position_id
LEFT JOIN LATERAL (
    SELECT * FROM fact_big_five_assessment 
    WHERE employee_id = e.employee_id 
    ORDER BY assessment_date_id DESC LIMIT 1
) bf ON TRUE
LEFT JOIN LATERAL (
    SELECT * FROM fact_dark_tetrad_assessment 
    WHERE employee_id = e.employee_id 
    ORDER BY assessment_date_id DESC LIMIT 1
) dt ON TRUE
LEFT JOIN LATERAL (
    SELECT * FROM fact_holland_assessment 
    WHERE employee_id = e.employee_id 
    ORDER BY assessment_date_id DESC LIMIT 1
) h ON TRUE
LEFT JOIN LATERAL (
    SELECT * FROM fact_psycap_assessment 
    WHERE employee_id = e.employee_id 
    ORDER BY assessment_date_id DESC LIMIT 1
) pc ON TRUE
WHERE e.is_active = TRUE;

-- View: Turnover Risk Analysis (Combines psychometrics + performance)
CREATE OR REPLACE VIEW view_turnover_risk AS
SELECT 
    e.employee_id,
    e.employee_code,
    e.first_name || ' ' || e.last_name AS full_name,
    d.department_name,
    p.position_title,
    
    -- Tenure
    CURRENT_DATE - e.hire_date AS tenure_days,
    
    -- Psychometric risk factors
    CASE 
        WHEN bf.agreeableness_t_score < 30 THEN 'High Risk'
        WHEN bf.agreeableness_t_score < 40 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS agreeableness_risk,
    
    CASE 
        WHEN pc.psycap_composite < 3.5 THEN 'High Risk'
        WHEN pc.psycap_composite < 4.5 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS psycap_risk,
    
    -- Performance
    perf.overall_rating AS latest_performance_rating,
    
    -- Composite risk score (0-100, higher = more risk)
    (
        (CASE WHEN bf.agreeableness_t_score < 40 THEN 30 ELSE 0 END) +
        (CASE WHEN pc.psycap_composite < 4.0 THEN 30 ELSE 0 END) +
        (CASE WHEN perf.overall_rating < 3.0 THEN 20 ELSE 0 END) +
        (CASE WHEN CURRENT_DATE - e.hire_date < 180 THEN 20 ELSE 0 END)
    ) AS risk_score
    
FROM dim_employee e
LEFT JOIN dim_department d ON e.department_id = d.department_id
LEFT JOIN dim_position p ON e.position_id = p.position_id
LEFT JOIN LATERAL (
    SELECT * FROM fact_big_five_assessment 
    WHERE employee_id = e.employee_id 
    ORDER BY assessment_date_id DESC LIMIT 1
) bf ON TRUE
LEFT JOIN LATERAL (
    SELECT * FROM fact_psycap_assessment 
    WHERE employee_id = e.employee_id 
    ORDER BY assessment_date_id DESC LIMIT 1
) pc ON TRUE
LEFT JOIN LATERAL (
    SELECT * FROM fact_performance 
    WHERE employee_id = e.employee_id 
    ORDER BY review_date_id DESC LIMIT 1
) perf ON TRUE
WHERE e.is_active = TRUE
ORDER BY risk_score DESC;

-- View: Department Psychometric Aggregates
CREATE OR REPLACE VIEW view_department_psychometrics AS
SELECT 
    d.department_name,
    COUNT(DISTINCT e.employee_id) AS employee_count,
    
    -- Big Five averages
    AVG(bf.extraversion_t_score) AS avg_extraversion,
    AVG(bf.agreeableness_t_score) AS avg_agreeableness,
    AVG(bf.conscientiousness_t_score) AS avg_conscientiousness,
    AVG(bf.neuroticism_t_score) AS avg_neuroticism,
    AVG(bf.openness_t_score) AS avg_openness,
    
    -- PsyCap average
    AVG(pc.psycap_composite) AS avg_psycap,
    
    -- Dark Tetrad averages
    AVG(dt.machiavellianism_standardized) AS avg_machiavellianism,
    
    -- Performance
    AVG(perf.overall_rating) AS avg_performance_rating
    
FROM dim_department d
JOIN dim_employee e ON d.department_id = e.department_id
LEFT JOIN fact_big_five_assessment bf ON e.employee_id = bf.employee_id
LEFT JOIN fact_psycap_assessment pc ON e.employee_id = pc.employee_id
LEFT JOIN fact_dark_tetrad_assessment dt ON e.employee_id = dt.employee_id
LEFT JOIN fact_performance perf ON e.employee_id = perf.employee_id
WHERE e.is_active = TRUE
GROUP BY d.department_id, d.department_name;

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Function: Calculate T-Score from raw score
CREATE OR REPLACE FUNCTION calculate_t_score(
    raw_score DECIMAL,
    population_mean DECIMAL,
    population_std DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
    RETURN ((raw_score - population_mean) / population_std) * 10 + 50;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Categorize PsyCap score
CREATE OR REPLACE FUNCTION categorize_psycap(psycap_score DECIMAL) 
RETURNS VARCHAR AS $$
BEGIN
    IF psycap_score >= 5.0 THEN
        RETURN 'High';
    ELSIF psycap_score >= 4.0 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'Low';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================================================
-- SAMPLE DATA POPULATION (For testing)
-- =============================================================================

-- Populate dim_date (2020-2030)
INSERT INTO dim_date (full_date, year, quarter, month, month_name, week, day_of_month, day_of_week, day_name, is_weekend)
SELECT 
    date_val::date,
    EXTRACT(YEAR FROM date_val)::int,
    EXTRACT(QUARTER FROM date_val)::int,
    EXTRACT(MONTH FROM date_val)::int,
    TO_CHAR(date_val, 'Month'),
    EXTRACT(WEEK FROM date_val)::int,
    EXTRACT(DAY FROM date_val)::int,
    EXTRACT(DOW FROM date_val)::int,
    TO_CHAR(date_val, 'Day'),
    EXTRACT(DOW FROM date_val)::int IN (0, 6)
FROM generate_series('2020-01-01'::date, '2030-12-31'::date, '1 day'::interval) AS date_val
ON CONFLICT (full_date) DO NOTHING;

-- Sample Departments
INSERT INTO dim_department (department_name, department_code) VALUES
('Human Resources', 'HR'),
('Information Technology', 'IT'),
('Finance', 'FIN'),
('Operations', 'OPS'),
('Sales', 'SALES'),
('Marketing', 'MKT')
ON CONFLICT (department_code) DO NOTHING;

-- Sample Positions
INSERT INTO dim_position (position_title, position_code, position_level, salary_band_min, salary_band_max) VALUES
('Data Analyst Junior', 'DA-JR', 1, 2500.00, 3500.00),
('Data Analyst Senior', 'DA-SR', 3, 5000.00, 7000.00),
('Data Engineer', 'DE', 3, 6000.00, 9000.00),
('HR Specialist', 'HR-SPEC', 2, 2800.00, 4000.00),
('Software Engineer', 'SWE', 2, 4000.00, 6000.00)
ON CONFLICT (position_code) DO NOTHING;

COMMENT ON DATABASE people_analytics IS 'Data warehouse for people analytics and psychometric assessments';
COMMENT ON TABLE fact_big_five_assessment IS 'Big Five personality traits (OCEAN) assessments';
COMMENT ON TABLE fact_dark_tetrad_assessment IS 'Dark Tetrad (Machiavellianism, Narcissism, Psychopathy, Sadism) assessments';
COMMENT ON TABLE fact_holland_assessment IS 'Holland Code (RIASEC) career interest assessments';
COMMENT ON TABLE fact_psycap_assessment IS 'Psychological Capital (Hope, Self-Efficacy, Resilience, Optimism) assessments';
