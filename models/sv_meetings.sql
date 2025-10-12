-- =====================================================
-- SILVER MEETINGS MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

WITH bronze_meetings AS (
    SELECT *
    FROM {{ source('bronze', 'bz_meetings') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN meeting_id IS NULL THEN 0 ELSE 1 END as meeting_id_check,
        CASE WHEN host_id IS NULL THEN 0 ELSE 1 END as host_id_check,
        CASE WHEN start_time IS NULL THEN 0 ELSE 1 END as start_time_check,
        CASE WHEN end_time IS NULL THEN 0 ELSE 1 END as end_time_check,
        CASE WHEN duration_minutes IS NULL THEN 0 ELSE 1 END as duration_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Range checks
        CASE WHEN end_time > start_time THEN 1 ELSE 0 END as time_logic_check,
        CASE WHEN duration_minutes > 0 AND duration_minutes <= 1440 THEN 1 ELSE 0 END as duration_range_check
    FROM bronze_meetings
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (meeting_id_check + host_id_check + start_time_check + end_time_check + 
             duration_check + source_system_check + time_logic_check + duration_range_check) / 8.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN meeting_id IS NULL OR host_id IS NULL OR start_time IS NULL OR end_time IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN end_time <= start_time THEN 'ERROR'
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_meetings AS (
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
    FROM quality_scored
    WHERE record_status = 'ACTIVE'
)

SELECT * FROM final_meetings
