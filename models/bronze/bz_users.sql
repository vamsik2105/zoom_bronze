{{ config(
    materialized='table'
) }}

-- Transform raw users data to bronze layer with 1-to-1 mapping
SELECT
    user_id,
    user_name,
    email,
    company,
    plan_type,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'users') }}
WHERE user_id IS NOT NULL
