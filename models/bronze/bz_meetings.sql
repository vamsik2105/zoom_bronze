{{ config(
    materialized='table'
) }}

-- Transform raw meetings data to bronze layer with 1-to-1 mapping
SELECT
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'meetings') }}
WHERE meeting_id IS NOT NULL
