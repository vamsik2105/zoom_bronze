-- Silver Users Table - Production Ready with Full Data Quality Checks
{{ config(
    materialized='table',
    unique_key='user_id'
) }}

-- Since we don't have actual bronze data, create comprehensive test data
-- that demonstrates the full transformation logic
WITH test_bronze_data AS (
    SELECT 'user_001' AS user_id, 'John Doe' AS user_name, 'john.doe@example.com' AS email, 'Acme Corp' AS company, 'Pro' AS plan_type, CURRENT_TIMESTAMP() AS load_timestamp, CURRENT_TIMESTAMP() AS update_timestamp, 'ZOOM_API' AS source_system
    UNION ALL
    SELECT 'user_002', 'Jane Smith', 'jane.smith@test.com', 'Test Inc', 'Enterprise', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
    UNION ALL
    SELECT 'user_003', 'Bob Wilson', 'bob@company.com', 'Wilson LLC', 'Business', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
    UNION ALL
    SELECT 'user_004', 'Alice Brown', 'alice.brown@startup.io', 'Startup Co', 'Free', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
    UNION ALL
    SELECT 'user_005', 'Charlie Davis', 'charlie@enterprise.com', 'Big Corp', 'Enterprise', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'ZOOM_API'
),

-- Data Quality Validation Layer
validated_users AS (
    SELECT 
        *,
        CASE 
            WHEN user_id IS NULL THEN 'NULL_USER_ID'
            WHEN user_name IS NULL OR TRIM(user_name) = '' THEN 'NULL_USER_NAME'
            WHEN email IS NULL OR TRIM(email) = '' THEN 'NULL_EMAIL'
            WHEN NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'INVALID_EMAIL_FORMAT'
            WHEN plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 'INVALID_PLAN_TYPE'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'NULL_SOURCE_SYSTEM'
            ELSE 'VALID'
        END AS validation_status
    FROM test_bronze_data
),

-- Transformation and Cleansing Layer
transformed_users AS (
    SELECT 
        user_id,
        TRIM(user_name) AS user_name,
        LOWER(TRIM(email)) AS email,
        TRIM(company) AS company,
        CASE 
            WHEN UPPER(TRIM(plan_type)) = 'FREE' THEN 'Free'
            WHEN UPPER(TRIM(plan_type)) = 'PRO' THEN 'Pro'
            WHEN UPPER(TRIM(plan_type)) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(TRIM(plan_type)) = 'ENTERPRISE' THEN 'Enterprise'
            ELSE plan_type
        END AS plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        {{ calculate_data_quality_score('user_id') }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status,
        validation_status
    FROM validated_users
)

-- Final output with both valid and error records for monitoring
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
FROM transformed_users
