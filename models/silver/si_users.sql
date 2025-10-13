{{ config(materialized='table') }}

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
    CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as null_user_id,
    CASE WHEN email IS NULL THEN 1 ELSE 0 END as null_email,
    CASE WHEN user_name IS NULL THEN 1 ELSE 0 END as null_user_name,
    
    -- Format validation
    CASE WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 1 ELSE 0 END as invalid_email_format,
    
    -- Domain validation
    CASE WHEN plan_type IS NOT NULL AND plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 1 ELSE 0 END as invalid_plan_type
  FROM source_data
),

-- Clean and transform data
transformed_data AS (
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
      WHEN (null_user_id + null_email + null_user_name + invalid_email_format + invalid_plan_type) = 0 THEN 1.0
      WHEN (null_user_id + null_email + null_user_name + invalid_email_format + invalid_plan_type) <= 2 THEN 0.8
      WHEN (null_user_id + null_email + null_user_name + invalid_email_format + invalid_plan_type) <= 3 THEN 0.6
      ELSE 0.4
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN (null_user_id + null_email + null_user_name) > 0 THEN 'error'
      WHEN (invalid_email_format + invalid_plan_type) > 0 THEN 'warning'
      ELSE 'active'
    END as record_status,
    
    -- Error flags for logging
    null_user_id,
    null_email,
    null_user_name,
    invalid_email_format,
    invalid_plan_type
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
FROM transformed_data
