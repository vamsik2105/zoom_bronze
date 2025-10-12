{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'si_participants', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED'",
    post_hook="UPDATE {{ ref('si_audit_log') }} SET status = 'COMPLETED', processing_time = 10 WHERE source_table = 'si_participants' AND status = 'STARTED'"
) }}

-- Transform bronze participants data to silver layer with data quality checks
WITH bronze_participants AS (
    SELECT *
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
        END AS validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN participant_id IS NOT NULL 
                AND meeting_id IS NOT NULL 
                AND join_time IS NOT NULL
                AND leave_time IS NOT NULL
                AND leave_time > join_time
            THEN 1.0
            WHEN participant_id IS NOT NULL AND meeting_id IS NOT NULL
            THEN 0.75
            WHEN participant_id IS NOT NULL
            THEN 0.5
            ELSE 0.0
        END AS data_quality_score
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_participants
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_participants
