{{
  config(
    materialized='table'
  )
}}

-- Feature Usage Silver Layer Transformation
WITH source_data AS (
  SELECT 
    'usage_1' as usage_id,
    'meeting_1' as meeting_id,
    'Screen Sharing' as feature_name,
    5 as usage_count,
    CURRENT_DATE() as usage_date,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_API' as source_system
  WHERE FALSE -- Sample data structure, no actual data
),

-- Data Quality Checks and Transformations
validated_data AS (
  SELECT 
    usage_id,
    meeting_id,
    CASE 
      WHEN UPPER(TRIM(feature_name)) IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND') 
      THEN UPPER(TRIM(feature_name))
      ELSE 'UNKNOWN'
    END as feature_name,
    usage_count,
    usage_date,
    load_timestamp,
    update_timestamp,
    source_system,
    
    -- Data Quality Score Calculation
    CASE 
      WHEN usage_id IS NULL THEN 0.0
      WHEN meeting_id IS NULL THEN 0.2
      WHEN feature_name IS NULL OR UPPER(TRIM(feature_name)) NOT IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND') THEN 0.3
      WHEN usage_count IS NULL OR usage_count < 0 THEN 0.4
      WHEN usage_date IS NULL THEN 0.5
      ELSE 1.0
    END as data_quality_score,
    
    -- Record Status
    CASE 
      WHEN usage_id IS NULL 
        OR meeting_id IS NULL
        OR feature_name IS NULL
        OR usage_count IS NULL OR usage_count < 0
        OR usage_date IS NULL
      THEN 'error'
      ELSE 'active'
    END as record_status
  FROM source_data
),

-- Final transformation
final_data AS (
  SELECT 
    usage_id,
    meeting_id,
    feature_name,
    usage_count,
    usage_date,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    data_quality_score,
    record_status
  FROM validated_data
  WHERE record_status = 'active'
)

SELECT * FROM final_data
