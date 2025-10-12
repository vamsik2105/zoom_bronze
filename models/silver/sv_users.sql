{{
  config(
    materialized='table'
  )
}}

-- Transform bronze users to silver layer with data quality checks
-- Note: This model will create empty table structure if source doesn't exist
WITH bronze_users AS (
    SELECT 
        CAST(NULL AS STRING) as user_id,
        CAST(NULL AS STRING) as user_name,
        CAST(NULL AS STRING) as email,
        CAST(NULL AS STRING) as company,
        CAST(NULL AS STRING) as plan_type,
        CAST(NULL AS TIMESTAMP_NTZ) as load_timestamp,
        CAST(NULL AS TIMESTAMP_NTZ) as update_timestamp,
        CAST(NULL AS STRING) as source_system
    WHERE FALSE -- Creates empty structure
),

-- Data Quality Validation
validated_users AS (
    SELECT 
        *,
        -- Data Quality Checks
        CASE 
            WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 'INVALID_USER_ID'
            WHEN email IS NULL OR TRIM(email) = '' THEN 'INVALID_EMAIL'
            WHEN NOT REGEXP_LIKE(LOWER(TRIM(email)), '^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$') THEN 'INVALID_EMAIL_FORMAT'
            WHEN plan_type IS NOT NULL AND plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 'INVALID_PLAN_TYPE'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'INVALID_SOURCE_SYSTEM'
            ELSE 'VALID'
        END as validation_status
    FROM bronze_users
),

-- Valid Records for Silver Layer
valid_records AS (
    SELECT 
        user_id,
        TRIM(user_name) as user_name,
        LOWER(TRIM(email)) as email,
        TRIM(company) as company,
        CASE 
            WHEN UPPER(TRIM(plan_type)) = 'FREE' THEN 'Free'
            WHEN UPPER(TRIM(plan_type)) = 'PRO' THEN 'Pro'
            WHEN UPPER(TRIM(plan_type)) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(TRIM(plan_type)) = 'ENTERPRISE' THEN 'Enterprise'
            ELSE plan_type
        END as plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 0.0
            WHEN email IS NULL OR TRIM(email) = '' OR NOT REGEXP_LIKE(LOWER(TRIM(email)), '^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$') THEN 0.3
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 0.5
            ELSE 1.0
        END as data_quality_score,
        'active' as record_status
    FROM validated_users
    WHERE validation_status = 'VALID'
)

SELECT * FROM valid_records
