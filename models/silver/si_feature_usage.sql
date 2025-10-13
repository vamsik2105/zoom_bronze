{{ config(
    materialized='table'
) }}

WITH bronze_feature_usage AS (
    SELECT *
    FROM BRONZE.bz_feature_usage
),

-- Data Quality Validations
validated_feature_usage AS (
    SELECT *,
        CASE 
            WHEN usage_id IS NULL THEN 'Missing usage_id'
            WHEN meeting_id IS NULL THEN 'Missing meeting_id'
            WHEN feature_name IS NULL THEN 'Missing feature_name'
            WHEN feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 'Invalid feature_name'
            WHEN usage_count IS NULL OR usage_count < 0 THEN 'Invalid usage_count'
            WHEN usage_date IS NULL THEN 'Missing usage_date'
            ELSE NULL
        END AS validation_error
    FROM bronze_feature_usage
),

-- Clean and Transform Data
transformed_feature_usage AS (
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
        END as feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
    FROM validated_feature_usage
)

SELECT 
    usage_id,
    meeting_id,
    feature_name,
    usage_count,
    usage_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    {{ calculate_data_quality_score('transformed_feature_usage') }} as data_quality_score,
    record_status
FROM transformed_feature_usage
WHERE validation_error IS NULL

UNION ALL

-- Error Records for Audit
SELECT 
    usage_id,
    meeting_id,
    feature_name,
    usage_count,
    usage_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    0.0 as data_quality_score,
    'error' as record_status
FROM transformed_feature_usage
WHERE validation_error IS NOT NULL
