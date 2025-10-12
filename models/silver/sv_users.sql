{{
  config(
    materialized='table'
  )
}}

-- Users Silver Layer Transformation
WITH source_data AS (
  SELECT *
  FROM {{ source('bronze', 'bz_users') }}
),

-- Data Quality Checks and Transformations
validated_data AS (
  SELECT 
    user_id,
    TRIM(user_name) as user_name,
    LOWER(TRIM(email)) as email,
    TRIM(company) as company,
    CASE 
      WHEN UPPER(TRIM(plan_type)) IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') 
      THEN UPPER(TRIM(plan_type))
      ELSE 'UNKNOWN'
    END as plan_type,
    load_timestamp,
    update_timestamp,
    source_system,
    
    -- Data Quality Score Calculation
    CASE 
      WHEN user_id IS NULL THEN 0.0
      WHEN user_name IS NULL OR TRIM(user_name) = '' THEN 0.2
      WHEN email IS NULL OR TRIM(email) = '' OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 0.3
      WHEN plan_type = 'UNKNOWN' THEN 0.7
      ELSE 1.0
    END as data_quality_score,
    
    -- Record Status
    CASE 
      WHEN user_id IS NULL 
        OR user_name IS NULL OR TRIM(user_name) = ''
        OR email IS NULL OR TRIM(email) = ''
        OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
      THEN 'error'
      ELSE 'active'
    END as record_status
  FROM source_data
),

-- Final transformation
final_data AS (
  SELECT 
    user_id,
    user_name,
    email,
    company,
    plan_type,
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
