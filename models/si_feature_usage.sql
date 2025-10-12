-- Silver layer feature usage table with data quality checks and transformations
-- Transforms bronze feature usage data with validation and cleansing

{{ config(
    materialized='table'
) }}

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
FROM {{ source('bronze', 'bz_feature_usage') }}
WHERE usage_id IS NOT NULL
  AND meeting_id IS NOT NULL
