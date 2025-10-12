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

-- Transform bronze feature usage to silver layer with data quality checks
WITH bronze_feature_usage AS (
    SELECT *
    FROM {{ source('bronze', 'bz_feature_usage') }}
),

-- Data Quality Validation
validated_feature_usage AS (
    SELECT 
        *,
        -- Data Quality Checks
        CASE 
            WHEN usage_id IS NULL OR TRIM(usage_id) = '' THEN 'INVALID_USAGE_ID'
            WHEN meeting_id IS NULL OR TRIM(meeting_id) = '' THEN 'INVALID_MEETING_ID'
            WHEN feature_name IS NULL OR TRIM(feature_name) = '' THEN 'INVALID_FEATURE_NAME'
            WHEN feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 'INVALID_FEATURE_TYPE'
            WHEN usage_count IS NULL OR usage_count < 0 THEN 'INVALID_USAGE_COUNT'
            WHEN usage_date IS NULL THEN 'INVALID_USAGE_DATE'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'INVALID_SOURCE_SYSTEM'
            ELSE 'VALID'
        END as validation_status
    FROM bronze_feature_usage
),

-- Valid Records for Silver Layer
valid_records AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN UPPER(TRIM(feature_name)) = 'SCREEN SHARING' THEN 'Screen Sharing'
            WHEN UPPER(TRIM(feature_name)) = 'CHAT' THEN 'Chat'
            WHEN UPPER(TRIM(feature_name)) = 'RECORDING' THEN 'Recording'
            WHEN UPPER(TRIM(feature_name)) = 'WHITEBOARD' THEN 'Whiteboard'
            WHEN UPPER(TRIM(feature_name)) = 'VIRTUAL BACKGROUND' THEN 'Virtual Background'
            ELSE feature_name
        END as feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        1.0 as data_quality_score,
        'active' as record_status
    FROM validated_feature_usage
    WHERE validation_status = 'VALID'
)

SELECT * FROM valid_records
