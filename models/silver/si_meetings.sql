{{
  config(
    materialized='table'
  )
}}

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

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN meeting_id IS NULL OR meeting_id = '' THEN 'INVALID_MEETING_ID'
            WHEN host_id IS NULL OR host_id = '' THEN 'MISSING_HOST_ID'
            WHEN start_time IS NULL THEN 'MISSING_START_TIME'
            WHEN end_time IS NULL THEN 'MISSING_END_TIME'
            WHEN end_time <= start_time THEN 'INVALID_TIME_RANGE'
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 'INVALID_DURATION'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN meeting_id IS NULL OR meeting_id = '' THEN 0.0
            WHEN host_id IS NULL OR host_id = '' THEN 0.3
            WHEN start_time IS NULL OR end_time IS NULL THEN 0.5
            WHEN end_time <= start_time THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_meetings
),

cleaned_meetings AS (
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_meetings
