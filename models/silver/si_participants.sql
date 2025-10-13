{{ config(materialized='table') }}

WITH bronze_participants AS (
    SELECT *
    FROM {{ source('bronze', 'bz_participants') }}
),

-- Data Quality Checks
quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN participant_id IS NULL THEN 0 ELSE 1 END as participant_id_complete,
        CASE WHEN meeting_id IS NULL THEN 0 ELSE 1 END as meeting_id_complete,
        CASE WHEN join_time IS NULL THEN 0 ELSE 1 END as join_time_complete,
        CASE WHEN leave_time IS NULL THEN 0 ELSE 1 END as leave_time_complete,
        
        -- Logic checks
        CASE WHEN leave_time > join_time THEN 1 ELSE 0 END as time_logic_valid
    FROM bronze_participants
),

-- Calculate data quality score
scored_data AS (
    SELECT 
        *,
        ROUND(
            (participant_id_complete + meeting_id_complete + join_time_complete + leave_time_complete + time_logic_valid) / 5.0, 2
        ) as data_quality_score,
        CASE 
            WHEN participant_id IS NULL OR meeting_id IS NULL OR join_time IS NULL OR leave_time IS NULL THEN 'error'
            WHEN leave_time <= join_time THEN 'error'
            ELSE 'active'
        END as record_status
    FROM quality_checks
),

-- Final transformation
final_data AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
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
