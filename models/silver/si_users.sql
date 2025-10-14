{{ config(
    materialized='table',
    unique_key='user_id'
) }}

-- Transform bronze users to silver users with data quality checks
WITH bronze_users AS (
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

-- Data quality validation
validated_users AS (
    SELECT 
        *,
        -- Data quality checks
        CASE 
            WHEN user_id IS NULL THEN 'NULL_USER_ID'
            WHEN user_name IS NULL THEN 'NULL_USER_NAME'
            WHEN email IS NULL THEN 'NULL_EMAIL'
            WHEN NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'INVALID_EMAIL_FORMAT'
            WHEN plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 'INVALID_PLAN_TYPE'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_users
),

-- Clean and transform valid records
clean_users AS (
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
        {{ calculate_data_quality_score() }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_users
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_users
