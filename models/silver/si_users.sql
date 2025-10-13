{{ config(materialized='table') }}

-- Silver Users Table - Clean and validated user data
WITH bronze_users AS (
    SELECT *
    FROM {{ source('bronze', 'bz_users') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as missing_user_id,
        CASE WHEN user_name IS NULL THEN 1 ELSE 0 END as missing_user_name,
        CASE WHEN email IS NULL THEN 1 ELSE 0 END as missing_email,
        
        -- Format validation
        CASE WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') 
             THEN 1 ELSE 0 END as invalid_email_format,
        
        -- Domain validation for plan_type
        CASE WHEN plan_type IS NOT NULL AND plan_type NOT IN ('Free','Pro','Business','Enterprise') 
             THEN 1 ELSE 0 END as invalid_plan_type,
        
        -- Calculate data quality score
        CASE 
            WHEN user_id IS NULL OR user_name IS NULL OR email IS NULL THEN 0.0
            WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 0.3
            WHEN plan_type IS NOT NULL AND plan_type NOT IN ('Free','Pro','Business','Enterprise') THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_users
),

-- Clean and transform data
cleaned_users AS (
    SELECT 
        user_id,
        TRIM(user_name) as user_name,
        LOWER(TRIM(email)) as email,
        TRIM(company) as company,
        CASE 
            WHEN plan_type IN ('Free','Pro','Business','Enterprise') THEN plan_type
            ELSE 'Free'  -- Default to Free for invalid values
        END as plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        CASE 
            WHEN missing_user_id = 1 OR missing_user_name = 1 OR missing_email = 1 OR invalid_email_format = 1 
            THEN 'error'
            ELSE 'active'
        END as record_status,
        -- Error flags for logging
        missing_user_id, missing_user_name, missing_email, invalid_email_format, invalid_plan_type
    FROM data_quality_checks
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
FROM cleaned_users
WHERE record_status = 'active'  -- Only include valid records
