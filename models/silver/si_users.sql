{{ config(materialized='table') }}

WITH bronze_users AS (
    SELECT * FROM {{ source('bronze', 'bz_users') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Quality score calculation
        CASE 
            WHEN user_id IS NULL THEN 0
            WHEN email IS NULL OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 0.3
            WHEN user_name IS NULL THEN 0.5
            WHEN plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 0.7
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN user_id IS NULL OR email IS NULL THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_users
),

-- Clean and transform data
cleaned_users AS (
    SELECT 
        user_id,
        TRIM(user_name) AS user_name,
        LOWER(TRIM(email)) AS email,
        TRIM(company) AS company,
        CASE 
            WHEN UPPER(plan_type) = 'FREE' THEN 'Free'
            WHEN UPPER(plan_type) = 'PRO' THEN 'Pro'
            WHEN UPPER(plan_type) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(plan_type) = 'ENTERPRISE' THEN 'Enterprise'
            ELSE plan_type
        END AS plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM dq_checks
    WHERE record_status = 'active'
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
