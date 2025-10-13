{{ config(materialized='table') }}

WITH bronze_meetings AS (
    SELECT *
    FROM {{ source('bronze', 'bz_meetings') }}
),

-- Data Quality Checks
quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN meeting_id IS NULL THEN 0 ELSE 1 END as meeting_id_complete,
        CASE WHEN host_id IS NULL THEN 0 ELSE 1 END as host_id_complete,
        CASE WHEN start_time IS NULL THEN 0 ELSE 1 END as start_time_complete,
        CASE WHEN end_time IS NULL THEN 0 ELSE 1 END as end_time_complete,
        
        -- Logic checks
        CASE WHEN end_time > start_time THEN 1 ELSE 0 END as time_logic_valid,
        CASE WHEN duration_minutes > 0 AND duration_minutes <= 1440 THEN 1 ELSE 0 END as duration_valid
    FROM bronze_meetings
),

-- Calculate data quality score
scored_data AS (
    SELECT 
        *,
        ROUND(
            (meeting_id_complete + host_id_complete + start_time_complete + end_time_complete + time_logic_valid + duration_valid) / 6.0, 2
        ) as data_quality_score,
        CASE 
            WHEN meeting_id IS NULL OR host_id IS NULL OR start_time IS NULL OR end_time IS NULL THEN 'error'
            WHEN end_time <= start_time THEN 'error'
            WHEN duration_minutes <= 0 OR duration_minutes > 1440 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM quality_checks
),

-- Final transformation
final_data AS (
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
        record_status
    FROM scored_data
    WHERE record_status = 'active'
)

SELECT * FROM final_data
