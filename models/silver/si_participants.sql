{{ config(
    materialized='table',
    unique_key='participant_id'
) }}

-- Silver Participants Table Transformation
WITH bronze_participants AS (
    SELECT *
    FROM {{ source('bronze', 'bz_participants') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Quality Score Calculation
        CASE 
            WHEN participant_id IS NULL THEN 0
            WHEN meeting_id IS NULL THEN 0.2
            WHEN join_time IS NULL OR leave_time IS NULL THEN 0.3
            WHEN leave_time <= join_time THEN 0.4
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN participant_id IS NULL OR meeting_id IS NULL THEN 'error'
            WHEN join_time IS NULL OR leave_time IS NULL THEN 'error'
            WHEN leave_time <= join_time THEN 'error'
            ELSE 'active'
        END AS record_status
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
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'active'
)

SELECT * FROM transformed_participants
