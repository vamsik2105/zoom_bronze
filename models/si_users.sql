-- Silver layer users table with data quality checks and transformations
-- Transforms bronze users data with validation and cleansing

{{ config(
    materialized='table'
) }}

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
    1.0 as data_quality_score,
    'active' as record_status
FROM {{ source('bronze', 'bz_users') }}
WHERE user_id IS NOT NULL
  AND email IS NOT NULL
