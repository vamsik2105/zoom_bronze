{{ config(materialized='table') }}

WITH source_data AS (
  SELECT 
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    load_timestamp,
    update_timestamp,
    source_system
  FROM {{ source('bronze', 'bz_licenses') }}
),

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE WHEN license_id IS NULL THEN 1 ELSE 0 END as null_license_id,
    CASE WHEN start_date IS NULL THEN 1 ELSE 0 END as null_start_date,
    CASE WHEN end_date IS NULL THEN 1 ELSE 0 END as null_end_date,
    
    -- Domain validation
    CASE WHEN license_type IS NOT NULL AND license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 1 ELSE 0 END as invalid_license_type,
    
    -- Logical consistency
    CASE WHEN start_date IS NOT NULL AND end_date IS NOT NULL AND end_date <= start_date THEN 1 ELSE 0 END as invalid_date_range
  FROM source_data
),

-- Clean and transform data
transformed_data AS (
  SELECT 
    license_id,
    CASE 
      WHEN UPPER(license_type) = 'PRO' THEN 'Pro'
      WHEN UPPER(license_type) = 'BUSINESS' THEN 'Business'
      WHEN UPPER(license_type) = 'ENTERPRISE' THEN 'Enterprise'
      WHEN UPPER(license_type) = 'EDUCATION' THEN 'Education'
      ELSE license_type
    END as license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    
    -- Calculate data quality score
    CASE 
      WHEN (null_license_id + null_start_date + null_end_date + invalid_license_type + invalid_date_range) = 0 THEN 1.0
      WHEN (null_license_id + null_start_date + null_end_date + invalid_license_type + invalid_date_range) <= 2 THEN 0.8
      WHEN (null_license_id + null_start_date + null_end_date + invalid_license_type + invalid_date_range) <= 3 THEN 0.6
      ELSE 0.4
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN (null_license_id + null_start_date + null_end_date) > 0 THEN 'error'
      WHEN (invalid_license_type + invalid_date_range) > 0 THEN 'warning'
      ELSE 'active'
    END as record_status
  FROM validated_data
)

SELECT 
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  load_timestamp,
  update_timestamp,
  source_system,
  load_date,
  update_date,
  data_quality_score,
  record_status
FROM transformed_data
