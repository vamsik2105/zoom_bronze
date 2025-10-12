{{
  config(
    materialized='table'
  )
}}

-- Meetings Silver Layer Transformation
WITH source_data AS (
  SELECT 
    'meeting_1' as meeting_id,
    'user_1' as host_id,
    'Team Meeting' as meeting_topic,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() + INTERVAL '1 HOUR' as end_time,
    60 as duration_minutes,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_API' as source_system
  WHERE FALSE -- Sample data structure, no actual data
),

-- Data Quality Checks and Transformations
validated_data AS (
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
    
    -- Data Quality Score Calculation
    CASE 
      WHEN meeting_id IS NULL THEN 0.0
      WHEN host_id IS NULL THEN 0.2
      WHEN start_time IS NULL OR end_time IS NULL THEN 0.3
      WHEN end_time <= start_time THEN 0.4
      WHEN duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440 THEN 0.5
      ELSE 1.0
    END as data_quality_score,
    
    -- Record Status
    CASE 
      WHEN meeting_id IS NULL 
        OR host_id IS NULL
        OR start_time IS NULL OR end_time IS NULL
        OR end_time <= start_time
        OR duration_minutes IS NULL OR duration_minutes <= 0 OR duration_minutes > 1440
      THEN 'error'
      ELSE 'active'
    END as record_status
  FROM source_data
),

-- Final transformation
final_data AS (
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
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    data_quality_score,
    record_status
  FROM validated_data
  WHERE record_status = 'active'
)

SELECT * FROM final_data
