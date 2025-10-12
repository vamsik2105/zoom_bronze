-- Silver layer meetings table with data quality checks and transformations
-- Transforms bronze meetings data with validation and cleansing

{{ config(
    materialized='table'
) }}

SELECT 
    meeting_id,
    host_id,
    TRIM(meeting_topic) as meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    1.0 as data_quality_score,
    'active' as record_status
FROM {{ source('bronze', 'bz_meetings') }}
WHERE meeting_id IS NOT NULL
  AND host_id IS NOT NULL
  AND start_time IS NOT NULL
  AND end_time IS NOT NULL
