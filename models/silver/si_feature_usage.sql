{{
  config(
    materialized='table'
  )
}}

-- Transform bronze feature usage to silver feature usage with data quality checks
WITH bronze_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('bronze', 'bz_feature_usage') }}
),

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN usage_id IS NULL OR usage_id = '' THEN 'INVALID_USAGE_ID'
            WHEN meeting_id IS NULL OR meeting_id = '' THEN 'MISSING_MEETING_ID'
            WHEN feature_name IS NULL OR feature_name = '' THEN 'MISSING_FEATURE_NAME'
            WHEN feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 'INVALID_FEATURE_NAME'
            WHEN usage_count IS NULL OR usage_count < 0 THEN 'INVALID_USAGE_COUNT'
            WHEN usage_date IS NULL THEN 'MISSING_USAGE_DATE'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN usage_id IS NULL OR usage_id = '' THEN 0.0
            WHEN meeting_id IS NULL OR meeting_id = '' THEN 0.3
            WHEN feature_name IS NULL OR feature_name = '' THEN 0.5
            WHEN usage_count IS NULL OR usage_count < 0 THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_feature_usage
),

cleaned_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN UPPER(feature_name) LIKE '%SCREEN%' THEN 'Screen Sharing'
            WHEN UPPER(feature_name) LIKE '%CHAT%' THEN 'Chat'
            WHEN UPPER(feature_name) LIKE '%RECORD%' THEN 'Recording'
            WHEN UPPER(feature_name) LIKE '%WHITEBOARD%' THEN 'Whiteboard'
            WHEN UPPER(feature_name) LIKE '%BACKGROUND%' THEN 'Virtual Background'
            ELSE feature_name
        END as feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_feature_usage
