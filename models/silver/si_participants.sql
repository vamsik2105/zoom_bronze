{{
  config(
    materialized='table'
  )
}}

-- Transform bronze participants to silver participants with data quality checks
WITH bronze_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('bronze', 'bz_participants') }}
),

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN participant_id IS NULL OR participant_id = '' THEN 'INVALID_PARTICIPANT_ID'
            WHEN meeting_id IS NULL OR meeting_id = '' THEN 'MISSING_MEETING_ID'
            WHEN join_time IS NULL THEN 'MISSING_JOIN_TIME'
            WHEN leave_time IS NULL THEN 'MISSING_LEAVE_TIME'
            WHEN leave_time <= join_time THEN 'INVALID_TIME_RANGE'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN participant_id IS NULL OR participant_id = '' THEN 0.0
            WHEN meeting_id IS NULL OR meeting_id = '' THEN 0.3
            WHEN join_time IS NULL OR leave_time IS NULL THEN 0.5
            WHEN leave_time <= join_time THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_participants
),

cleaned_participants AS (
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
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_participants
