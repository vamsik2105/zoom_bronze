{{ config(
    materialized='table'
) }}

-- Transform raw billing_events data to bronze layer with 1-to-1 mapping
SELECT
    event_id,
    user_id,
    event_type,
    amount,
    event_date,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'billing_events') }}
WHERE event_id IS NOT NULL
