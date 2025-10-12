{{
  config(
    materialized='table',
    pre_hook="""
      {% if this.name != 'sv_audit_log' %}
        INSERT INTO {{ ref('sv_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
        VALUES ('{{ this.name }}', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED')
      {% endif %}
    """,
    post_hook="""
      {% if this.name != 'sv_audit_log' %}
        INSERT INTO {{ ref('sv_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
        VALUES ('{{ this.name }}', CURRENT_TIMESTAMP(), 'dbt_transformation', 1, 'COMPLETED')
      {% endif %}
    """
  )
}}

-- Transform bronze meetings to silver layer with data quality checks
WITH bronze_meetings AS (
    SELECT *
    FROM {{ source('bronze', 'bz_meetings') }}
),

-- Data Quality Validation
validated_meetings AS (
    SELECT 
        *,
        -- Data Quality Checks
        CASE 
            WHEN meeting_id IS NULL OR TRIM(meeting_id) = '' THEN 'INVALID_MEETING_ID'
            WHEN host_id IS NULL OR TRIM(host_id) = '' THEN 'INVALID_HOST_ID'
            WHEN start_time IS NULL THEN 'INVALID_START_TIME'
            WHEN end_time IS NULL THEN 'INVALID_END_TIME'
            WHEN end_time <= start_time THEN 'INVALID_TIME_RANGE'
            WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 'INVALID_DURATION'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'INVALID_SOURCE_SYSTEM'
            ELSE 'VALID'
        END as validation_status
    FROM bronze_meetings
),

-- Valid Records for Silver Layer
valid_records AS (
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
        1.0 as data_quality_score,
        'active' as record_status
    FROM validated_meetings
    WHERE validation_status = 'VALID'
)

SELECT * FROM valid_records
