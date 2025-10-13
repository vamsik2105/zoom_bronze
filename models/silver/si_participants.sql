{{ config(materialized='table') }}

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
    CASE WHEN participant_id IS NULL THEN 1 ELSE 0 END as null_participant_id,
    CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as null_meeting_id,
    CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as null_user_id,
    CASE WHEN join_time IS NULL THEN 1 ELSE 0 END as null_join_time,
    CASE WHEN leave_time IS NULL THEN 1 ELSE 0 END as null_leave_time,
    
    -- Logical consistency
    CASE WHEN join_time IS NOT NULL AND leave_time IS NOT NULL AND leave_time <= join_time THEN 1 ELSE 0 END as invalid_time_range
  FROM source_data
),

-- Clean and transform data
transformed_data AS (
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
      WHEN (null_participant_id + null_meeting_id + null_user_id + null_join_time + null_leave_time + invalid_time_range) = 0 THEN 1.0
      WHEN (null_participant_id + null_meeting_id + null_user_id + null_join_time + null_leave_time + invalid_time_range) <= 2 THEN 0.8
      WHEN (null_participant_id + null_meeting_id + null_user_id + null_join_time + null_leave_time + invalid_time_range) <= 3 THEN 0.6
      ELSE 0.4
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN (null_participant_id + null_meeting_id + null_user_id + null_join_time + null_leave_time) > 0 THEN 'error'
      WHEN invalid_time_range > 0 THEN 'warning'
      ELSE 'active'
    END as record_status
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
FROM transformed_data
