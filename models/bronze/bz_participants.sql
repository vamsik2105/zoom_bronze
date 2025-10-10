{{ config(
    materialized='table'
) }}

-- Transform raw participants data to bronze layer with 1-to-1 mapping
SELECT
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'participants') }}
WHERE participant_id IS NOT NULL
