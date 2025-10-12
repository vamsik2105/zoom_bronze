-- Silver layer meetings table with data quality checks and transformations
-- Transforms bronze meetings data with validation and cleansing

{{ config(
    materialized='table',
    pre_hook=[
        "{{ log_audit_start('si_meetings') }}"
    ],
    post_hook=[
        "{{ log_audit_end('si_meetings') }}"
    ]
) }}

WITH bronze_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('bronze', 'bz_meetings') }}
),

-- Data quality validation
validated_meetings AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as null_meeting_id,
        CASE WHEN host_id IS NULL THEN 1 ELSE 0 END as null_host_id,
        CASE WHEN start_time IS NULL THEN 1 ELSE 0 END as null_start_time,
        CASE WHEN end_time IS NULL THEN 1 ELSE 0 END as null_end_time,
        
        -- Logical validation
        CASE WHEN end_time IS NOT NULL AND start_time IS NOT NULL AND end_time <= start_time 
             THEN 1 ELSE 0 END as invalid_time_range,
        CASE WHEN duration_minutes IS NOT NULL AND (duration_minutes < 0 OR duration_minutes > 1440) 
             THEN 1 ELSE 0 END as invalid_duration
    FROM bronze_meetings
),

-- Clean and transform data
cleaned_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        TRIM(meeting_topic) as meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        
        -- Data quality flags
        null_meeting_id + null_host_id + null_start_time + null_end_time + invalid_time_range + invalid_duration as error_count,
        
        -- Record status
        CASE 
            WHEN null_meeting_id = 1 OR null_host_id = 1 OR null_start_time = 1 OR null_end_time = 1 OR invalid_time_range = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_meetings
),

-- Calculate data quality score
final_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
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
    FROM cleaned_meetings
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_meetings
