{{ config(
    materialized='table',
    unique_key='meeting_id'
) }}

-- Silver Meetings Table Transformation
WITH bronze_meetings AS (
    SELECT *
    FROM {{ source('bronze', 'bz_meetings') }}
),

-- Data Quality Checks
data_quality_checks AS (
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
        -- Quality Score Calculation
        CASE 
            WHEN meeting_id IS NULL THEN 0
            WHEN host_id IS NULL THEN 0.2
            WHEN start_time IS NULL OR end_time IS NULL THEN 0.3
            WHEN end_time <= start_time THEN 0.4
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 0.5
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN meeting_id IS NULL OR host_id IS NULL OR start_time IS NULL OR end_time IS NULL THEN 'error'
            WHEN end_time <= start_time THEN 'error'
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_meetings
),

-- Clean and Transform Data
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
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'active'
)

SELECT * FROM transformed_meetings
