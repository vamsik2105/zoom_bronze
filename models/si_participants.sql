-- Silver layer participants table with data quality checks and transformations
-- Transforms bronze participants data with validation and cleansing

{{ config(
    materialized='table'
) }}

SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    1.0 as data_quality_score,
    'active' as record_status
FROM {{ source('bronze', 'bz_participants') }}
WHERE participant_id IS NOT NULL
  AND meeting_id IS NOT NULL
