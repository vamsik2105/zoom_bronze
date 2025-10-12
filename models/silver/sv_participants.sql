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

-- Transform bronze participants to silver layer with data quality checks
WITH bronze_participants AS (
    SELECT *
    FROM {{ source('bronze', 'bz_participants') }}
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
