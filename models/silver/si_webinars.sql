{{ config(materialized='table') }}

WITH source_data AS (
  SELECT 
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    registrants,
    load_timestamp,
    update_timestamp,
    source_system
  FROM {{ source('bronze', 'bz_webinars') }}
),

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE WHEN webinar_id IS NULL THEN 1 ELSE 0 END as null_webinar_id,
    CASE WHEN host_id IS NULL THEN 1 ELSE 0 END as null_host_id,
    CASE WHEN start_time IS NULL THEN 1 ELSE 0 END as null_start_time,
    CASE WHEN end_time IS NULL THEN 1 ELSE 0 END as null_end_time,
    
    -- Range validation
    CASE WHEN registrants IS NOT NULL AND registrants < 0 THEN 1 ELSE 0 END as negative_registrants,
    
    -- Logical consistency
    CASE WHEN start_time IS NOT NULL AND end_time IS NOT NULL AND end_time <= start_time THEN 1 ELSE 0 END as invalid_time_range
  FROM source_data
),

-- Clean and transform data
transformed_data AS (
  SELECT 
    webinar_id,
    host_id,
    TRIM(webinar_topic) as webinar_topic,
    start_time,
    end_time,
    registrants,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    
    -- Calculate data quality score
    CASE 
      WHEN (null_webinar_id + null_host_id + null_start_time + null_end_time + negative_registrants + invalid_time_range) = 0 THEN 1.0
      WHEN (null_webinar_id + null_host_id + null_start_time + null_end_time + negative_registrants + invalid_time_range) <= 2 THEN 0.8
      WHEN (null_webinar_id + null_host_id + null_start_time + null_end_time + negative_registrants + invalid_time_range) <= 3 THEN 0.6
      ELSE 0.4
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN (null_webinar_id + null_host_id + null_start_time + null_end_time) > 0 THEN 'error'
      WHEN (negative_registrants + invalid_time_range) > 0 THEN 'warning'
      ELSE 'active'
    END as record_status
  FROM validated_data
)

SELECT 
  webinar_id,
  host_id,
  webinar_topic,
  start_time,
  end_time,
  registrants,
  load_timestamp,
  update_timestamp,
  source_system,
  load_date,
  update_date,
  data_quality_score,
  record_status
FROM transformed_data
