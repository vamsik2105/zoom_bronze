{{
  config(
    materialized='table'
  )
}}

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
    CASE 
      WHEN license_id IS NULL THEN 'MISSING_LICENSE_ID'
      WHEN license_type IS NULL THEN 'MISSING_LICENSE_TYPE'
      WHEN start_date IS NULL THEN 'MISSING_START_DATE'
      WHEN end_date IS NULL THEN 'MISSING_END_DATE'
      ELSE 'VALID'
    END as completeness_status,
    
    -- Domain and logic validation
    CASE 
      WHEN license_type IS NOT NULL AND license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 'INVALID_LICENSE_TYPE'
      WHEN end_date IS NOT NULL AND start_date IS NOT NULL AND end_date <= start_date THEN 'INVALID_DATE_RANGE'
      ELSE 'VALID_DOMAIN'
    END as domain_status
  FROM source_data
),

-- Clean and transform data
cleaned_data AS (
  SELECT 
    license_id,
    CASE 
      WHEN UPPER(TRIM(license_type)) = 'PRO' THEN 'Pro'
      WHEN UPPER(TRIM(license_type)) = 'BUSINESS' THEN 'Business'
      WHEN UPPER(TRIM(license_type)) = 'ENTERPRISE' THEN 'Enterprise'
      WHEN UPPER(TRIM(license_type)) = 'EDUCATION' THEN 'Education'
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
      WHEN completeness_status != 'VALID' OR domain_status != 'VALID_DOMAIN' THEN 0.0
      WHEN license_id IS NOT NULL AND license_type IS NOT NULL AND start_date IS NOT NULL AND end_date IS NOT NULL THEN 1.0
      ELSE 0.7
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN completeness_status = 'VALID' AND domain_status = 'VALID_DOMAIN' THEN 'active'
      ELSE 'error'
    END as record_status,
    
    completeness_status,
    domain_status
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
FROM cleaned_data
WHERE record_status = 'active'
