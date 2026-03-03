-- =============================================================================
-- stg_employees.sql
-- Capa: Staging
-- Fuente: {{ source('raw', 'employees') }}
--
-- Propósito:
--   Limpia y anonimiza datos crudos de empleados. Hashea campos PII
--   (nombres, email) usando MD5 para compliance con protección de datos.
--   Normaliza tipos, coalesces NULLs, y filtra registros inválidos.
-- =============================================================================

{{ config(
    materialized = 'view',
    tags         = ['staging', 'pii', 'employees']
) }}

with source as (

    select * from {{ source('raw', 'employees') }}

),

cleaned as (

    select
        -- =====================================================================
        -- Identificadores (sin PII)
        -- =====================================================================
        employee_id,

        -- =====================================================================
        -- PII Hasheada — MD5 para anonimización (GDPR / LPDP compliance)
        -- Los datos originales NUNCA pasan de esta capa
        -- =====================================================================
        md5(lower(trim(coalesce(first_name, 'unknown'))))  as first_name_hash,
        md5(lower(trim(coalesce(last_name, 'unknown'))))   as last_name_hash,
        md5(lower(trim(coalesce(email, 'no-email'))))      as email_hash,

        -- =====================================================================
        -- Dimensiones organizacionales
        -- =====================================================================
        coalesce(department_id, -1)  as department_id,
        coalesce(position_id, -1)   as position_id,

        -- =====================================================================
        -- Fechas normalizadas
        -- =====================================================================
        cast(hire_date as date)                            as hire_date,
        cast(termination_date as date)                     as termination_date,

        -- =====================================================================
        -- Métricas derivadas
        -- =====================================================================
        coalesce(is_active, true)                          as is_active,
        coalesce(salary, 0)::numeric(12, 2)               as salary,

        -- Antigüedad calculada (días)
        case
            when termination_date is not null
                then (cast(termination_date as date) - cast(hire_date as date))
            else (current_date - cast(hire_date as date))
        end                                                as tenure_days,

        -- =====================================================================
        -- Metadata de auditoría
        -- =====================================================================
        current_timestamp                                  as _loaded_at

    from source

    -- Filtrar registros obviamente inválidos
    where employee_id is not null
      and hire_date is not null

)

select * from cleaned
