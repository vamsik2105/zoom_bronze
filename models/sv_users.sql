-- =====================================================
-- SILVER USERS MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

WITH bronze_users AS (
    SELECT *
    FROM {{ source('bronze', 'bz_users') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN user_id IS NULL THEN 0 ELSE 1 END as user_id_check,
        CASE WHEN user_name IS NULL OR TRIM(user_name) = '' THEN 0 ELSE 1 END as user_name_check,
        CASE WHEN email IS NULL OR TRIM(email) = '' THEN 0 ELSE 1 END as email_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Format checks
        CASE WHEN email IS NOT NULL AND REGEXP_LIKE(LOWER(TRIM(email)), '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN 1 ELSE 0 END as email_format_check,
        
        -- Domain checks
        CASE WHEN plan_type IS NULL OR plan_type IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 1 ELSE 0 END as plan_type_check
    FROM bronze_users
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (user_id_check + user_name_check + email_check + source_system_check + 
             email_format_check + plan_type_check) / 6.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN user_id IS NULL OR user_name IS NULL OR email IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN NOT REGEXP_LIKE(LOWER(TRIM(email)), '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN 'ERROR'
            WHEN plan_type IS NOT NULL AND plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_users AS (
    SELECT 
        user_id,
        TRIM(user_name) as user_name,
        LOWER(TRIM(email)) as email,
        TRIM(company) as company,
        CASE 
            WHEN plan_type IN ('Free', 'Pro', 'Business', 'Enterprise') THEN plan_type
            ELSE 'Free' -- Default to Free for invalid values
        END as plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        record_status
    FROM quality_scored
    WHERE record_status = 'ACTIVE' -- Only include valid records
)

SELECT * FROM final_users
