{{
  config(
    materialized='table'
  )
}}

-- Participants Silver Layer Transformation
WITH source_data AS (
  SELECT 
    'participant_1' as participant_id,
    'meeting_1' as meeting_id,
    'user_1' as user_id,
    CURRENT_TIMESTAMP() as join_time,
    CURRENT_TIMESTAMP() + INTERVAL '30 MINUTES' as leave_time,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_API' as source_system
  WHERE FALSE -- Sample data structure, no actual data
),

-- Data Quality Checks and Transformations
validated_data AS (
  SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system,
    
    -- Data Quality Score Calculation
    CASE 
      WHEN participant_id IS NULL THEN 0.0
      WHEN meeting_id IS NULL THEN 0.2
      WHEN join_time IS NULL OR leave_time IS NULL THEN 0.3
      WHEN leave_time <= join_time THEN 0.4
      ELSE 1.0
    END as data_quality_score,
    
    -- Record Status
    CASE 
      WHEN participant_id IS NULL 
        OR meeting_id IS NULL
        OR join_time IS NULL OR leave_time IS NULL
        OR leave_time <= join_time
      THEN 'error'
      ELSE 'active'
    END as record_status
  FROM source_data
),

-- Final transformation
final_data AS (
  SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
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
