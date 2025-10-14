{{ config(
    materialized='table',
    unique_key='participant_id'
) }}

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

-- Data quality validation
validated_participants AS (
    SELECT 
        *,
        CASE 
            WHEN participant_id IS NULL THEN 'NULL_PARTICIPANT_ID'
            WHEN meeting_id IS NULL THEN 'NULL_MEETING_ID'
            WHEN join_time IS NULL THEN 'NULL_JOIN_TIME'
            WHEN leave_time IS NULL THEN 'NULL_LEAVE_TIME'
            WHEN leave_time <= join_time THEN 'INVALID_TIME_RANGE'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_participants
),

-- Clean and transform valid records
clean_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        CASE 
            WHEN participant_id IS NOT NULL AND meeting_id IS NOT NULL 
                 AND join_time IS NOT NULL AND leave_time IS NOT NULL 
                 AND leave_time > join_time THEN 1.0
            ELSE 0.5
        END AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_participants
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_participants
