{{ config(
    materialized='table',
    unique_key='meeting_id'
) }}

-- Transform bronze meetings to silver meetings with data quality checks
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
    FROM {{ source('bronze', 'bz_meetings') }}
),

-- Data quality validation
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
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_meetings
),

-- Clean and transform valid records
clean_meetings AS (
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
        CASE 
            WHEN meeting_id IS NOT NULL AND host_id IS NOT NULL 
                 AND start_time IS NOT NULL AND end_time IS NOT NULL 
                 AND end_time > start_time AND duration_minutes > 0 THEN 1.0
            ELSE 0.5
        END AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_meetings
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_meetings
