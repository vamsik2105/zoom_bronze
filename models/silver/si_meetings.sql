{{ config(
    materialized='table'
) }}

-- Meetings Silver Layer Transformation
WITH bronze_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system
    FROM BRONZE.bz_meetings
    WHERE load_timestamp IS NOT NULL
),

validated_meetings AS (
    SELECT *,
        CASE 
            WHEN meeting_id IS NULL OR TRIM(meeting_id) = '' THEN 'Missing meeting_id'
            WHEN host_id IS NULL OR TRIM(host_id) = '' THEN 'Missing host_id'
            WHEN start_time IS NULL THEN 'Missing start_time'
            WHEN end_time IS NULL THEN 'Missing end_time'
            WHEN end_time <= start_time THEN 'Invalid time range'
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 'Invalid duration'
            ELSE NULL
        END AS validation_error
    FROM bronze_meetings
),

transformed_meetings AS (
    SELECT 
        TRIM(meeting_id) as meeting_id,
        TRIM(host_id) as host_id,
        CASE 
            WHEN meeting_topic IS NOT NULL THEN TRIM(meeting_topic)
            ELSE 'Untitled Meeting'
        END as meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN (
                CASE WHEN meeting_id IS NOT NULL THEN 0.25 ELSE 0.0 END +
                CASE WHEN host_id IS NOT NULL THEN 0.25 ELSE 0.0 END +
                CASE WHEN start_time IS NOT NULL THEN 0.25 ELSE 0.0 END +
                CASE WHEN duration_minutes > 0 THEN 0.25 ELSE 0.0 END
            )
            ELSE 0.0
        END as data_quality_score,
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
    data_quality_score,
    record_status
FROM transformed_meetings
