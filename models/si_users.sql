-- Silver layer users table with data quality checks and transformations
-- Transforms bronze users data with validation and cleansing

{{ config(
    materialized='table',
    pre_hook=[
        "{{ log_audit_start('si_users') }}"
    ],
    post_hook=[
        "{{ log_audit_end('si_users') }}"
    ]
) }}

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
        -- Completeness checks
        CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as null_user_id,
        CASE WHEN email IS NULL THEN 1 ELSE 0 END as null_email,
        CASE WHEN user_name IS NULL THEN 1 ELSE 0 END as null_user_name,
        
        -- Format validation
        CASE WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') 
             THEN 1 ELSE 0 END as invalid_email_format,
        
        -- Domain validation
        CASE WHEN plan_type IS NOT NULL AND plan_type NOT IN ('Free','Pro','Business','Enterprise') 
             THEN 1 ELSE 0 END as invalid_plan_type
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
        
        -- Data quality flags
        null_user_id + null_email + null_user_name + invalid_email_format + invalid_plan_type as error_count,
        
        -- Record status
        CASE 
            WHEN null_user_id = 1 OR null_email = 1 OR invalid_email_format = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_users
),

-- Calculate data quality score
final_users AS (
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
        
        -- Data quality score calculation
        CASE 
            WHEN error_count = 0 THEN 1.0
            WHEN error_count = 1 THEN 0.8
            WHEN error_count = 2 THEN 0.6
            WHEN error_count = 3 THEN 0.4
            WHEN error_count = 4 THEN 0.2
            ELSE 0.0
        END as data_quality_score,
        
        record_status
    FROM cleaned_users
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_users
