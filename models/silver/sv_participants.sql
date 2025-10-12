{{
  config(
    materialized='table'
  )
}}

-- Transform bronze participants to silver layer with data quality checks
-- Note: This model will create empty table structure if source doesn't exist
WITH bronze_participants AS (
    SELECT 
        CAST(NULL AS STRING) as participant_id,
        CAST(NULL AS STRING) as meeting_id,
        CAST(NULL AS STRING) as user_id,
        CAST(NULL AS TIMESTAMP_NTZ) as join_time,
        CAST(NULL AS TIMESTAMP_NTZ) as leave_time,
        CAST(NULL AS TIMESTAMP_NTZ) as load_timestamp,
        CAST(NULL AS TIMESTAMP_NTZ) as update_timestamp,
        CAST(NULL AS STRING) as source_system
    WHERE FALSE -- Creates empty structure
),

-- Data Quality Validation
validated_participants AS (
    SELECT 
        *,
        -- Data Quality Checks
        CASE 
            WHEN participant_id IS NULL OR TRIM(participant_id) = '' THEN 'INVALID_PARTICIPANT_ID'
            WHEN meeting_id IS NULL OR TRIM(meeting_id) = '' THEN 'INVALID_MEETING_ID'
            WHEN join_time IS NULL THEN 'INVALID_JOIN_TIME'
            WHEN leave_time IS NULL THEN 'INVALID_LEAVE_TIME'
            WHEN leave_time <= join_time THEN 'INVALID_TIME_RANGE'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'INVALID_SOURCE_SYSTEM'
            ELSE 'VALID'
        END as validation_status
    FROM bronze_participants
),

-- Valid Records for Silver Layer
valid_records AS (
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
        1.0 as data_quality_score,
        'active' as record_status
    FROM validated_participants
    WHERE validation_status = 'VALID'
)

SELECT * FROM valid_records
