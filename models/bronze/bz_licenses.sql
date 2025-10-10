{{ config(
    materialized='table'
) }}

-- Transform raw licenses data to bronze layer with 1-to-1 mapping
SELECT
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'licenses') }}
WHERE license_id IS NOT NULL
