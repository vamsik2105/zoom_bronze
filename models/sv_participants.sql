-- =====================================================
-- SILVER PARTICIPANTS MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

WITH bronze_participants AS (
    SELECT *
    FROM {{ source('bronze', 'bz_participants') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN participant_id IS NULL THEN 0 ELSE 1 END as participant_id_check,
        CASE WHEN meeting_id IS NULL THEN 0 ELSE 1 END as meeting_id_check,
        CASE WHEN join_time IS NULL THEN 0 ELSE 1 END as join_time_check,
        CASE WHEN leave_time IS NULL THEN 0 ELSE 1 END as leave_time_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Logic checks
        CASE WHEN leave_time > join_time THEN 1 ELSE 0 END as time_logic_check
    FROM bronze_participants
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (participant_id_check + meeting_id_check + join_time_check + leave_time_check + 
             source_system_check + time_logic_check) / 6.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN participant_id IS NULL OR meeting_id IS NULL OR join_time IS NULL OR leave_time IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN leave_time <= join_time THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_participants AS (
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
    FROM quality_scored
    WHERE record_status = 'ACTIVE'
)

SELECT * FROM final_participants
