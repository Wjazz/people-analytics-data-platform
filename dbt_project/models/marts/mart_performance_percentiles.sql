-- =============================================================================
-- mart_performance_percentiles.sql
-- Capa: Marts (Analytics)
-- Upstream: {{ ref('stg_employees') }}, {{ source('raw', 'performance_reviews') }}
--
-- Propósito:
--   Calcula el percentil de rendimiento SEMANAL de cada empleado dentro de
--   su departamento utilizando PERCENT_RANK() Window Function.
--
--   Lógica análoga al cálculo de percentil_rendimiento en métricas
--   personales del sistema Bourbaki — ahora escalado a toda la organización.
-- =============================================================================

{{ config(
    materialized = 'table',
    tags         = ['marts', 'performance', 'analytics'],
    post_hook    = [
        "CREATE INDEX IF NOT EXISTS idx_perf_pctl_employee ON {{ this }} (employee_id)",
        "CREATE INDEX IF NOT EXISTS idx_perf_pctl_week     ON {{ this }} (review_week)",
        "CREATE INDEX IF NOT EXISTS idx_perf_pctl_dept     ON {{ this }} (department_id, review_week)"
    ]
) }}

with employees as (

    select * from {{ ref('stg_employees') }}

),

reviews as (

    select
        review_id,
        employee_id,
        review_date,
        overall_rating,
        department_id,
        -- Truncar a semana ISO para agrupar por período semanal
        date_trunc('week', cast(review_date as date))  as review_week
    from {{ source('raw', 'performance_reviews') }}
    where review_date is not null
      and overall_rating is not null

),

-- =============================================================================
-- CTE Principal: Percentil de rendimiento semanal por departamento
--
-- PERCENT_RANK() = (rank - 1) / (total_rows - 1)
-- Rango: [0.0, 1.0] donde 1.0 = top performer del departamento esa semana
-- =============================================================================

weekly_percentiles as (

    select
        r.review_id,
        r.employee_id,
        r.department_id,
        r.review_week,
        r.review_date,
        r.overall_rating,

        -- ─────────────────────────────────────────────────────
        -- Percentil de rendimiento dentro del departamento
        -- por semana (Window Function)
        -- ─────────────────────────────────────────────────────
        percent_rank() over (
            partition by r.department_id, r.review_week
            order by r.overall_rating asc
        ) as performance_percentile,

        -- Ranking ordinal para referencia
        rank() over (
            partition by r.department_id, r.review_week
            order by r.overall_rating desc
        ) as department_rank,

        -- Total de empleados evaluados en el departamento esa semana
        count(*) over (
            partition by r.department_id, r.review_week
        ) as peers_evaluated,

        -- Media departamental esa semana (para contexto)
        avg(r.overall_rating) over (
            partition by r.department_id, r.review_week
        ) as department_avg_rating,

        -- Desviación estándar departamental
        stddev_pop(r.overall_rating) over (
            partition by r.department_id, r.review_week
        ) as department_stddev_rating

    from reviews r

),

-- =============================================================================
-- Enriquecimiento con datos de empleado (ya anonimizados)
-- =============================================================================

enriched as (

    select
        wp.review_id,
        wp.employee_id,
        e.first_name_hash,
        e.last_name_hash,
        wp.department_id,
        e.is_active,
        e.tenure_days,

        -- Temporalidad
        wp.review_week,
        wp.review_date,

        -- Rating crudo
        wp.overall_rating,

        -- ─── Métricas de percentil ───
        round(wp.performance_percentile::numeric, 4)   as performance_percentile,
        wp.department_rank,
        wp.peers_evaluated,
        round(wp.department_avg_rating::numeric, 2)    as department_avg_rating,
        round(wp.department_stddev_rating::numeric, 4) as department_stddev_rating,

        -- ─── Categorización por cuartil ───
        case
            when wp.performance_percentile >= 0.75 then 'Top Performer'
            when wp.performance_percentile >= 0.50 then 'Above Average'
            when wp.performance_percentile >= 0.25 then 'Below Average'
            else 'Needs Improvement'
        end as performance_tier,

        -- ─── Z-Score para detección de outliers ───
        case
            when wp.department_stddev_rating > 0
            then round(
                ((wp.overall_rating - wp.department_avg_rating) / wp.department_stddev_rating)::numeric,
                2
            )
            else 0
        end as z_score,

        -- Metadata
        current_timestamp as _calculated_at

    from weekly_percentiles wp
    left join employees e
        on wp.employee_id = e.employee_id

)

select * from enriched
