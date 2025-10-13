{{ config(materialized='table') }}

WITH bronze_users AS (
    SELECT *
    FROM {{ source('bronze', 'bz_users') }}
),

-- Data Quality Checks
quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN user_id IS NULL THEN 0 ELSE 1 END as user_id_complete,
        CASE WHEN user_name IS NULL OR TRIM(user_name) = '' THEN 0 ELSE 1 END as user_name_complete,
        CASE WHEN email IS NULL OR TRIM(email) = '' THEN 0 ELSE 1 END as email_complete,
        
        -- Format checks
        CASE WHEN email IS NOT NULL AND REGEXP_LIKE(LOWER(TRIM(email)), '^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$') THEN 1 ELSE 0 END as email_valid,
        
        -- Domain checks
        CASE WHEN plan_type IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 1 ELSE 0 END as plan_type_valid
    FROM bronze_users
),

-- Calculate data quality score
scored_data AS (
    SELECT 
        *,
        ROUND(
            (user_id_complete + user_name_complete + email_complete + email_valid + plan_type_valid) / 5.0, 2
        ) as data_quality_score,
        CASE 
            WHEN user_id IS NULL OR email IS NULL OR user_name IS NULL THEN 'error'
            WHEN NOT REGEXP_LIKE(LOWER(TRIM(email)), '^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$') THEN 'error'
            ELSE 'active'
        END as record_status
    FROM quality_checks
),

-- Final transformation
final_data AS (
    SELECT 
        user_id,
        TRIM(user_name) as user_name,
        LOWER(TRIM(email)) as email,
        TRIM(company) as company,
        CASE 
            WHEN plan_type IN ('Free', 'Pro', 'Business', 'Enterprise') THEN plan_type
            ELSE 'Unknown'
        END as plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        record_status
    FROM scored_data
    WHERE record_status = 'active'
)

SELECT * FROM final_data
