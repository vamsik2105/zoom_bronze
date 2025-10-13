{{
  config(
    materialized='table'
  )
}}

WITH source_data AS (
  SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system
  FROM {{ source('bronze', 'bz_participants') }}
),

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE 
      WHEN participant_id IS NULL THEN 'MISSING_PARTICIPANT_ID'
      WHEN meeting_id IS NULL THEN 'MISSING_MEETING_ID'
      WHEN join_time IS NULL THEN 'MISSING_JOIN_TIME'
      WHEN leave_time IS NULL THEN 'MISSING_LEAVE_TIME'
      ELSE 'VALID'
    END as completeness_status,
    
    -- Logic validation
    CASE 
      WHEN leave_time IS NOT NULL AND join_time IS NOT NULL AND leave_time <= join_time THEN 'INVALID_TIME_RANGE'
      ELSE 'VALID_LOGIC'
    END as logic_status
  FROM source_data
),

-- Clean and transform data
cleaned_data AS (
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
    
    -- Calculate data quality score
    CASE 
      WHEN completeness_status != 'VALID' OR logic_status != 'VALID_LOGIC' THEN 0.0
      WHEN participant_id IS NOT NULL AND meeting_id IS NOT NULL AND join_time IS NOT NULL AND leave_time IS NOT NULL THEN 1.0
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
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  load_timestamp,
  update_timestamp,
  source_system,
  load_date,
  update_date,
  data_quality_score,
  record_status
FROM cleaned_data
WHERE record_status = 'active'
