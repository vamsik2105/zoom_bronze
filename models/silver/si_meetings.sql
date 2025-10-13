{{ config(
    materialized='table'
) }}

WITH bronze_meetings AS (
    SELECT *
    FROM BRONZE.bz_meetings
),

-- Data Quality Validations
validated_meetings AS (
    SELECT *,
        CASE 
            WHEN meeting_id IS NULL THEN 'Missing meeting_id'
            WHEN host_id IS NULL THEN 'Missing host_id'
            WHEN start_time IS NULL THEN 'Missing start_time'
            WHEN end_time IS NULL THEN 'Missing end_time'
            WHEN end_time <= start_time THEN 'Invalid time range'
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 'Invalid duration'
            ELSE NULL
        END AS validation_error
    FROM bronze_meetings
),

-- Clean and Transform Data
transformed_meetings AS (
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
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
    FROM validated_meetings
)

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
    load_date,
    update_date,
    CASE 
        WHEN record_status = 'error' THEN 0.0
        ELSE (
            CASE WHEN load_timestamp IS NOT NULL THEN 0.25 ELSE 0.0 END +
            CASE WHEN update_timestamp IS NOT NULL THEN 0.25 ELSE 0.0 END +
            CASE WHEN source_system IS NOT NULL THEN 0.25 ELSE 0.0 END +
            0.25 -- Base score for valid record
        )
    END as data_quality_score,
    record_status
FROM transformed_meetings
WHERE validation_error IS NULL

UNION ALL

-- Error Records for Audit
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
    load_date,
    update_date,
    0.0 as data_quality_score,
    'error' as record_status
FROM transformed_meetings
WHERE validation_error IS NOT NULL
