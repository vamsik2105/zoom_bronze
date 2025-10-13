{{ config(
    materialized='table'
) }}

WITH bronze_participants AS (
    SELECT *
    FROM {{ source('bronze', 'bz_participants') }}
),

-- Data Quality Validations
validated_participants AS (
    SELECT *,
        CASE 
            WHEN participant_id IS NULL THEN 'Missing participant_id'
            WHEN meeting_id IS NULL THEN 'Missing meeting_id'
            WHEN join_time IS NULL THEN 'Missing join_time'
            WHEN leave_time IS NULL THEN 'Missing leave_time'
            WHEN leave_time <= join_time THEN 'Invalid time range'
            ELSE NULL
        END AS validation_error
    FROM bronze_participants
),

-- Clean and Transform Data
transformed_participants AS (
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
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
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
    {{ calculate_data_quality_score('transformed_participants') }} as data_quality_score,
    record_status
FROM transformed_participants
WHERE validation_error IS NULL

UNION ALL

-- Error Records for Audit
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
    0.0 as data_quality_score,
    'error' as record_status
FROM transformed_participants
WHERE validation_error IS NOT NULL
