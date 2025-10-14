{{ config(
    materialized='table',
    unique_key='usage_id'
) }}

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

-- Data quality validation
validated_feature_usage AS (
    SELECT 
        *,
        CASE 
            WHEN usage_id IS NULL THEN 'NULL_USAGE_ID'
            WHEN meeting_id IS NULL THEN 'NULL_MEETING_ID'
            WHEN feature_name IS NULL THEN 'NULL_FEATURE_NAME'
            WHEN feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 'INVALID_FEATURE_NAME'
            WHEN usage_count IS NULL OR usage_count < 0 THEN 'INVALID_USAGE_COUNT'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_feature_usage
),

-- Clean and transform valid records
clean_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN UPPER(feature_name) = 'SCREEN SHARING' THEN 'Screen Sharing'
            WHEN UPPER(feature_name) = 'CHAT' THEN 'Chat'
            WHEN UPPER(feature_name) = 'RECORDING' THEN 'Recording'
            WHEN UPPER(feature_name) = 'WHITEBOARD' THEN 'Whiteboard'
            WHEN UPPER(feature_name) = 'VIRTUAL BACKGROUND' THEN 'Virtual Background'
            ELSE feature_name
        END AS feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        CASE 
            WHEN usage_id IS NOT NULL AND meeting_id IS NOT NULL 
                 AND feature_name IS NOT NULL AND usage_count >= 0 THEN 1.0
            ELSE 0.5
        END AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_feature_usage
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_feature_usage
