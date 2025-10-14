{{ config(
    materialized='table',
    unique_key='user_id'
) }}

-- Silver Users Table Transformation
WITH bronze_users AS (
    SELECT *
    FROM {{ source('bronze', 'bz_users') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Quality Score Calculation
        CASE 
            WHEN user_id IS NULL THEN 0
            WHEN email IS NULL OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 0.3
            WHEN user_name IS NULL THEN 0.5
            WHEN plan_type NOT IN ('Free','Pro','Business','Enterprise') THEN 0.7
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN user_id IS NULL OR email IS NULL OR user_name IS NULL THEN 'error'
            WHEN NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 'error'
            WHEN plan_type NOT IN ('Free','Pro','Business','Enterprise') THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_users
),

-- Clean and Transform Data
transformed_users AS (
    SELECT 
        user_id,
        TRIM(user_name) AS user_name,
        LOWER(TRIM(email)) AS email,
        TRIM(company) AS company,
        CASE 
            WHEN UPPER(plan_type) IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') 
            THEN UPPER(plan_type)
            ELSE 'UNKNOWN'
        END AS plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'active'
)

SELECT * FROM transformed_users
