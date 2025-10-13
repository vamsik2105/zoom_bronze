{{ config(
    materialized='table'
) }}

-- Participants Silver Layer Transformation
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
    FROM BRONZE.bz_participants
    WHERE load_timestamp IS NOT NULL
),

validated_participants AS (
    SELECT *,
        CASE 
            WHEN participant_id IS NULL OR TRIM(participant_id) = '' THEN 'Missing participant_id'
            WHEN meeting_id IS NULL OR TRIM(meeting_id) = '' THEN 'Missing meeting_id'
            WHEN join_time IS NULL THEN 'Missing join_time'
            WHEN leave_time IS NULL THEN 'Missing leave_time'
            WHEN leave_time <= join_time THEN 'Invalid time range'
            ELSE NULL
        END AS validation_error
    FROM bronze_participants
),

transformed_participants AS (
    SELECT 
        TRIM(participant_id) as participant_id,
        TRIM(meeting_id) as meeting_id,
        TRIM(user_id) as user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN (
                CASE WHEN participant_id IS NOT NULL THEN 0.25 ELSE 0.0 END +
                CASE WHEN meeting_id IS NOT NULL THEN 0.25 ELSE 0.0 END +
                CASE WHEN join_time IS NOT NULL THEN 0.25 ELSE 0.0 END +
                CASE WHEN leave_time IS NOT NULL THEN 0.25 ELSE 0.0 END
            )
            ELSE 0.0
        END as data_quality_score,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status
    FROM validated_participants
)

SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM transformed_participants
