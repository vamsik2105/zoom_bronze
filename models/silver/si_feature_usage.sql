{{
  config(
    materialized='table'
  )
}}

WITH source_data AS (
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

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE 
      WHEN usage_id IS NULL THEN 'MISSING_USAGE_ID'
      WHEN meeting_id IS NULL THEN 'MISSING_MEETING_ID'
      WHEN feature_name IS NULL THEN 'MISSING_FEATURE_NAME'
      WHEN usage_count IS NULL THEN 'MISSING_USAGE_COUNT'
      WHEN usage_date IS NULL THEN 'MISSING_USAGE_DATE'
      ELSE 'VALID'
    END as completeness_status,
    
    -- Format and domain validation
    CASE 
      WHEN feature_name IS NOT NULL AND feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 'INVALID_FEATURE_NAME'
      WHEN usage_count IS NOT NULL AND usage_count < 0 THEN 'INVALID_USAGE_COUNT'
      ELSE 'VALID_FORMAT'
    END as format_status
  FROM source_data
),

-- Clean and transform data
cleaned_data AS (
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
    
    -- Calculate data quality score
    CASE 
      WHEN completeness_status != 'VALID' OR format_status != 'VALID_FORMAT' THEN 0.0
      WHEN usage_id IS NOT NULL AND meeting_id IS NOT NULL AND feature_name IS NOT NULL THEN 1.0
      ELSE 0.7
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN completeness_status = 'VALID' AND format_status = 'VALID_FORMAT' THEN 'active'
      ELSE 'error'
    END as record_status,
    
    completeness_status,
    format_status
  FROM validated_data
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
FROM cleaned_data
WHERE record_status = 'active'
