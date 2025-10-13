{{ config(
    materialized='table'
) }}

-- Users Silver Layer Transformation
-- Transforms bronze user data with data quality checks and cleansing

WITH bronze_users AS (
    -- Source data from bronze layer
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        load_timestamp,
        update_timestamp,
        source_system
    FROM BRONZE.bz_users
    WHERE load_timestamp IS NOT NULL
),

-- Data Quality Validation Layer
validated_users AS (
    SELECT *,
        CASE 
            WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 'Missing user_id'
            WHEN email IS NULL OR TRIM(email) = '' THEN 'Missing email'
            WHEN user_name IS NULL OR TRIM(user_name) = '' THEN 'Missing user_name'
            WHEN NOT REGEXP_LIKE(TRIM(email), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 'Invalid email format'
            WHEN UPPER(TRIM(plan_type)) NOT IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') THEN 'Invalid plan_type'
            WHEN load_timestamp > CURRENT_TIMESTAMP() THEN 'Future load timestamp'
            WHEN update_timestamp > CURRENT_TIMESTAMP() THEN 'Future update timestamp'
            ELSE NULL
        END AS validation_error,
        
        -- Data Quality Score Calculation
        CASE 
            WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 0
            WHEN email IS NULL OR TRIM(email) = '' THEN 0
            WHEN user_name IS NULL OR TRIM(user_name) = '' THEN 0
            WHEN NOT REGEXP_LIKE(TRIM(email), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 0
            WHEN UPPER(TRIM(plan_type)) NOT IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') THEN 0
            ELSE (
                CASE WHEN user_id IS NOT NULL THEN 0.2 ELSE 0.0 END +
                CASE WHEN email IS NOT NULL AND REGEXP_LIKE(TRIM(email), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 0.2 ELSE 0.0 END +
                CASE WHEN user_name IS NOT NULL THEN 0.2 ELSE 0.0 END +
                CASE WHEN plan_type IS NOT NULL THEN 0.2 ELSE 0.0 END +
                CASE WHEN source_system IS NOT NULL THEN 0.2 ELSE 0.0 END
            )
        END AS data_quality_score
    FROM bronze_users
),

-- Data Cleansing and Transformation Layer
transformed_users AS (
    SELECT 
        TRIM(user_id) as user_id,
        TRIM(user_name) as user_name,
        LOWER(TRIM(email)) as email,
        CASE 
            WHEN company IS NOT NULL THEN TRIM(company)
            ELSE 'Unknown'
        END as company,
        CASE 
            WHEN UPPER(TRIM(plan_type)) = 'FREE' THEN 'Free'
            WHEN UPPER(TRIM(plan_type)) = 'PRO' THEN 'Pro'
            WHEN UPPER(TRIM(plan_type)) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(TRIM(plan_type)) = 'ENTERPRISE' THEN 'Enterprise'
            ELSE 'Unknown'
        END as plan_type,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
    FROM validated_users
),

-- Final Output with Error Segregation
final_users AS (
    -- Valid Records
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
    WHERE validation_error IS NULL
    
    UNION ALL
    
    -- Error Records (for audit purposes)
    SELECT 
        COALESCE(user_id, 'ERROR_' || {{ dbt_utils.generate_surrogate_key(['email', 'user_name']) }}) as user_id,
        COALESCE(user_name, 'ERROR_RECORD') as user_name,
        COALESCE(email, 'error@unknown.com') as email,
        COALESCE(company, 'ERROR') as company,
        COALESCE(plan_type, 'ERROR') as plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        load_date,
        update_date,
        0.0 as data_quality_score,
        'error' as record_status
    FROM transformed_users
    WHERE validation_error IS NOT NULL
)

SELECT * FROM final_users
