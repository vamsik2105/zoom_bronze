-- Silver layer participants table with data quality checks and transformations
-- Transforms bronze participants data with validation and cleansing

{{ config(
    materialized='table'
) }}

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
        -- Completeness checks
        CASE WHEN participant_id IS NULL THEN 1 ELSE 0 END as null_participant_id,
        CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as null_meeting_id,
        CASE WHEN join_time IS NULL THEN 1 ELSE 0 END as null_join_time,
        CASE WHEN leave_time IS NULL THEN 1 ELSE 0 END as null_leave_time,
        
        -- Logical validation
        CASE WHEN leave_time IS NOT NULL AND join_time IS NOT NULL AND leave_time <= join_time 
             THEN 1 ELSE 0 END as invalid_time_range
    FROM bronze_participants
),

-- Clean and transform data
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
        
        -- Data quality flags
        null_participant_id + null_meeting_id + null_join_time + null_leave_time + invalid_time_range as error_count,
        
        -- Record status
        CASE 
            WHEN null_participant_id = 1 OR null_meeting_id = 1 OR null_join_time = 1 OR null_leave_time = 1 OR invalid_time_range = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_participants
),

-- Calculate data quality score
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
        load_date,
        update_date,
        
        -- Data quality score calculation
        CASE 
            WHEN error_count = 0 THEN 1.0
            WHEN error_count = 1 THEN 0.8
            WHEN error_count = 2 THEN 0.6
            WHEN error_count = 3 THEN 0.4
            WHEN error_count = 4 THEN 0.2
            ELSE 0.0
        END as data_quality_score,
        
        record_status
    FROM cleaned_participants
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_participants
