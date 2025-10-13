{{ config(materialized='table') }}

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
    CASE WHEN usage_id IS NULL THEN 1 ELSE 0 END as null_usage_id,
    CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as null_meeting_id,
    CASE WHEN feature_name IS NULL THEN 1 ELSE 0 END as null_feature_name,
    
    -- Range validation
    CASE WHEN usage_count IS NOT NULL AND usage_count < 0 THEN 1 ELSE 0 END as negative_usage_count,
    
    -- Domain validation
    CASE WHEN feature_name IS NOT NULL AND feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 1 ELSE 0 END as invalid_feature_name
  FROM source_data
),

-- Clean and transform data
transformed_data AS (
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
    
    -- Calculate data quality score
    CASE 
      WHEN (null_usage_id + null_meeting_id + null_feature_name + negative_usage_count + invalid_feature_name) = 0 THEN 1.0
      WHEN (null_usage_id + null_meeting_id + null_feature_name + negative_usage_count + invalid_feature_name) <= 2 THEN 0.8
      WHEN (null_usage_id + null_meeting_id + null_feature_name + negative_usage_count + invalid_feature_name) <= 3 THEN 0.6
      ELSE 0.4
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN (null_usage_id + null_meeting_id + null_feature_name) > 0 THEN 'error'
      WHEN (negative_usage_count + invalid_feature_name) > 0 THEN 'warning'
      ELSE 'active'
    END as record_status
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
FROM transformed_data
