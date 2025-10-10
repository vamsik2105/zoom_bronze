{{ config(
    materialized='table'
) }}

-- Transform raw webinars data to bronze layer with 1-to-1 mapping
SELECT
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    registrants,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'webinars') }}
WHERE webinar_id IS NOT NULL
