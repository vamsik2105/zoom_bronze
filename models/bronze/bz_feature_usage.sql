{{ config(
    materialized='table'
) }}

-- Transform raw feature_usage data to bronze layer with 1-to-1 mapping
SELECT
    usage_id,
    meeting_id,
    feature_name,
    usage_count,
    usage_date,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'feature_usage') }}
WHERE usage_id IS NOT NULL
