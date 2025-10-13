{{
  config(
    materialized='table'
  )
}}

WITH source_data AS (
  SELECT 
    user_id,
    user_name,
    email,
    company,
    plan_type,
    load_timestamp,
    update_timestamp,
    source_system
  FROM {{ source('bronze', 'bz_users') }}
),

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE 
      WHEN user_id IS NULL THEN 'MISSING_USER_ID'
      WHEN user_name IS NULL THEN 'MISSING_USER_NAME'
      WHEN email IS NULL THEN 'MISSING_EMAIL'
      WHEN plan_type IS NULL THEN 'MISSING_PLAN_TYPE'
      ELSE 'VALID'
    END as completeness_status,
    
    -- Format validation
    CASE 
      WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 'INVALID_EMAIL_FORMAT'
      WHEN plan_type IS NOT NULL AND plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 'INVALID_PLAN_TYPE'
      ELSE 'VALID_FORMAT'
    END as format_status
  FROM source_data
),

-- Clean and transform data
cleaned_data AS (
  SELECT 
    user_id,
    TRIM(user_name) as user_name,
    LOWER(TRIM(email)) as email,
    TRIM(company) as company,
    CASE 
      WHEN UPPER(plan_type) = 'FREE' THEN 'Free'
      WHEN UPPER(plan_type) = 'PRO' THEN 'Pro'
      WHEN UPPER(plan_type) = 'BUSINESS' THEN 'Business'
      WHEN UPPER(plan_type) = 'ENTERPRISE' THEN 'Enterprise'
      ELSE plan_type
    END as plan_type,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    
    -- Calculate data quality score
    CASE 
      WHEN completeness_status != 'VALID' OR format_status != 'VALID_FORMAT' THEN 0.0
      WHEN user_id IS NOT NULL AND email IS NOT NULL AND user_name IS NOT NULL THEN 1.0
      ELSE 0.7
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN completeness_status = 'VALID' AND format_status = 'VALID_FORMAT' THEN 'active'
      ELSE 'error'
    END as record_status,
    
    completeness_status,
    format_status
  FROM validated_data
)

SELECT 
  user_id,
  user_name,
  email,
  company,
  plan_type,
  load_timestamp,
  update_timestamp,
  source_system,
  load_date,
  update_date,
  data_quality_score,
  record_status
FROM cleaned_data
WHERE record_status = 'active'
