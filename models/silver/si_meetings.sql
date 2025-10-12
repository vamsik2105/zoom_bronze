-- Silver Meetings Table - Production Ready with Full Data Quality Checks
{{ config(
    materialized='table',
    unique_key='meeting_id'
) }}

-- Comprehensive test data demonstrating meeting transformations
WITH test_bronze_meetings AS (
    SELECT 'meeting_001' AS meeting_id, 'user_001' AS host_id, 'Weekly Team Standup' AS meeting_topic, 
           CURRENT_TIMESTAMP() AS start_time, DATEADD('hour', 1, CURRENT_TIMESTAMP()) AS end_time, 
           60 AS duration_minutes, CURRENT_TIMESTAMP() AS load_timestamp, 
           CURRENT_TIMESTAMP() AS update_timestamp, 'ZOOM_API' AS source_system
    UNION ALL
    SELECT 'meeting_002', 'user_002', 'Product Demo', 
           CURRENT_TIMESTAMP(), DATEADD('minute', 30, CURRENT_TIMESTAMP()), 
           30, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
    UNION ALL
    SELECT 'meeting_003', 'user_003', 'Client Presentation', 
           CURRENT_TIMESTAMP(), DATEADD('hour', 2, CURRENT_TIMESTAMP()), 
           120, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
    UNION ALL
    SELECT 'meeting_004', 'user_004', 'Training Session', 
           CURRENT_TIMESTAMP(), DATEADD('hour', 3, CURRENT_TIMESTAMP()), 
           180, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
    UNION ALL
    SELECT 'meeting_005', 'user_005', 'Board Meeting', 
           CURRENT_TIMESTAMP(), DATEADD('hour', 4, CURRENT_TIMESTAMP()), 
           240, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
),

-- Data Quality Validation for Meetings
validated_meetings AS (
    SELECT 
        *,
        CASE 
            WHEN meeting_id IS NULL THEN 'NULL_MEETING_ID'
            WHEN host_id IS NULL THEN 'NULL_HOST_ID'
            WHEN start_time IS NULL THEN 'NULL_START_TIME'
            WHEN end_time IS NULL THEN 'NULL_END_TIME'
            WHEN end_time <= start_time THEN 'INVALID_TIME_RANGE'
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 'INVALID_DURATION'
            WHEN source_system IS NULL THEN 'NULL_SOURCE_SYSTEM'
            ELSE 'VALID'
        END AS validation_status
    FROM test_bronze_meetings
),

-- Meeting Transformation Layer
transformed_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        TRIM(meeting_topic) AS meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        {{ calculate_data_quality_score('meeting_id') }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status,
        validation_status
    FROM validated_meetings
)

-- Final meeting output
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
