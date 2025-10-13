{{ config(materialized='table') }}

-- Silver Meetings Table - Clean and validated meeting data
WITH bronze_meetings AS (
    SELECT *
    FROM {{ source('bronze', 'bz_meetings') }}
),

valid_users AS (
    SELECT DISTINCT user_id
    FROM {{ ref('si_users') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        bm.*,
        -- Completeness checks
        CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as missing_meeting_id,
        CASE WHEN host_id IS NULL THEN 1 ELSE 0 END as missing_host_id,
        CASE WHEN start_time IS NULL THEN 1 ELSE 0 END as missing_start_time,
        CASE WHEN end_time IS NULL THEN 1 ELSE 0 END as missing_end_time,
        
        -- Logical consistency checks
        CASE WHEN start_time IS NOT NULL AND end_time IS NOT NULL AND end_time <= start_time 
             THEN 1 ELSE 0 END as invalid_time_range,
        CASE WHEN duration_minutes IS NOT NULL AND (duration_minutes <= 0 OR duration_minutes > 1440) 
             THEN 1 ELSE 0 END as invalid_duration,
        
        -- Referential integrity
        CASE WHEN host_id IS NOT NULL AND vu.user_id IS NULL THEN 1 ELSE 0 END as invalid_host_ref,
        
        -- Calculate data quality score
        CASE 
            WHEN meeting_id IS NULL OR host_id IS NULL OR start_time IS NULL OR end_time IS NULL THEN 0.0
            WHEN end_time <= start_time THEN 0.2
            WHEN duration_minutes <= 0 OR duration_minutes > 1440 THEN 0.4
            WHEN vu.user_id IS NULL THEN 0.6
            ELSE 1.0
        END as data_quality_score
    FROM bronze_meetings bm
    LEFT JOIN valid_users vu ON bm.host_id = vu.user_id
),

-- Clean and transform data
cleaned_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        TRIM(meeting_topic) as meeting_topic,
        start_time,
        end_time,
        CASE 
            WHEN duration_minutes IS NOT NULL AND duration_minutes > 0 AND duration_minutes <= 1440 
            THEN duration_minutes
            ELSE DATEDIFF('minute', start_time, end_time)  -- Calculate if invalid
        END as duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        CASE 
            WHEN missing_meeting_id = 1 OR missing_host_id = 1 OR missing_start_time = 1 
                 OR missing_end_time = 1 OR invalid_time_range = 1 OR invalid_host_ref = 1
            THEN 'error'
            ELSE 'active'
        END as record_status
    FROM data_quality_checks
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
FROM cleaned_meetings
WHERE record_status = 'active'
