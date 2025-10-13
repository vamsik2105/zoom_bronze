{{ config(
    materialized='table'
) }}

-- Feature Usage Silver Layer Transformation
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
    FROM BRONZE.bz_feature_usage
    WHERE load_timestamp IS NOT NULL
),

validated_feature_usage AS (
    SELECT *,
        CASE 
            WHEN usage_id IS NULL OR TRIM(usage_id) = '' THEN 'Missing usage_id'
            WHEN meeting_id IS NULL OR TRIM(meeting_id) = '' THEN 'Missing meeting_id'
            WHEN feature_name IS NULL OR TRIM(feature_name) = '' THEN 'Missing feature_name'
            WHEN UPPER(TRIM(feature_name)) NOT IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND') THEN 'Invalid feature_name'
            WHEN usage_count IS NULL OR usage_count < 0 THEN 'Invalid usage_count'
            WHEN usage_date IS NULL THEN 'Missing usage_date'
            ELSE NULL
        END AS validation_error
    FROM bronze_feature_usage
),

transformed_feature_usage AS (
    SELECT 
        TRIM(usage_id) as usage_id,
        TRIM(meeting_id) as meeting_id,
        CASE 
            WHEN UPPER(TRIM(feature_name)) = 'SCREEN SHARING' THEN 'Screen Sharing'
            WHEN UPPER(TRIM(feature_name)) = 'CHAT' THEN 'Chat'
            WHEN UPPER(TRIM(feature_name)) = 'RECORDING' THEN 'Recording'
            WHEN UPPER(TRIM(feature_name)) = 'WHITEBOARD' THEN 'Whiteboard'
            WHEN UPPER(TRIM(feature_name)) = 'VIRTUAL BACKGROUND' THEN 'Virtual Background'
            ELSE 'Unknown Feature'
        END as feature_name,
        COALESCE(usage_count, 0) as usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 1.0
            ELSE 0.0
        END as data_quality_score,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status
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
    data_quality_score,
    record_status
FROM transformed_feature_usage
