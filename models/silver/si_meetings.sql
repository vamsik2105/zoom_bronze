{{
  config(
    materialized='table'
  )
}}

WITH source_data AS (
  SELECT 
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system
  FROM {{ source('bronze', 'bz_meetings') }}
),

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE 
      WHEN meeting_id IS NULL THEN 'MISSING_MEETING_ID'
      WHEN host_id IS NULL THEN 'MISSING_HOST_ID'
      WHEN start_time IS NULL THEN 'MISSING_START_TIME'
      WHEN end_time IS NULL THEN 'MISSING_END_TIME'
      WHEN duration_minutes IS NULL THEN 'MISSING_DURATION'
      ELSE 'VALID'
    END as completeness_status,
    
    -- Logic validation
    CASE 
      WHEN end_time IS NOT NULL AND start_time IS NOT NULL AND end_time <= start_time THEN 'INVALID_TIME_RANGE'
      WHEN duration_minutes IS NOT NULL AND (duration_minutes < 0 OR duration_minutes > 1440) THEN 'INVALID_DURATION'
      ELSE 'VALID_LOGIC'
    END as logic_status
  FROM source_data
),

-- Clean and transform data
cleaned_data AS (
  SELECT 
    meeting_id,
    host_id,
    TRIM(meeting_topic) as meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    
    -- Calculate data quality score
    CASE 
      WHEN completeness_status != 'VALID' OR logic_status != 'VALID_LOGIC' THEN 0.0
      WHEN meeting_id IS NOT NULL AND host_id IS NOT NULL AND start_time IS NOT NULL AND end_time IS NOT NULL THEN 1.0
      ELSE 0.7
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN completeness_status = 'VALID' AND logic_status = 'VALID_LOGIC' THEN 'active'
      ELSE 'error'
    END as record_status,
    
    completeness_status,
    logic_status
  FROM validated_data
)

SELECT 
  meeting_id,
  host_id,
  meeting_topic,
  start_time,
  end_time,
  duration_minutes,
  load_timestamp,
  update_timestamp,
  source_system,
  load_date,
  update_date,
  data_quality_score,
  record_status
FROM cleaned_data
WHERE record_status = 'active'
