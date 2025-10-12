{{
  config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ invocation_id }}' || '_si_users', 'si_users', CURRENT_TIMESTAMP, 'STARTED', 'BRONZE', 'SILVER', 'ETL', CURRENT_DATE, CURRENT_DATE WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP, status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP), records_processed = (SELECT COUNT(*) FROM {{ this }}) WHERE execution_id = '{{ invocation_id }}' || '_si_users' AND '{{ this.name }}' != 'si_process_audit'"
  )
}}

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

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN user_id IS NULL OR user_id = '' THEN 'INVALID_USER_ID'
            WHEN email IS NULL OR email = '' THEN 'MISSING_EMAIL'
            WHEN NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'INVALID_EMAIL_FORMAT'
            WHEN user_name IS NULL OR user_name = '' THEN 'MISSING_USER_NAME'
            WHEN plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 'INVALID_PLAN_TYPE'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN user_id IS NULL OR user_id = '' THEN 0.0
            WHEN email IS NULL OR email = '' OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 0.3
            WHEN user_name IS NULL OR user_name = '' THEN 0.5
            WHEN plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_users
),

cleaned_users AS (
    SELECT 
        user_id,
        TRIM(user_name) as user_name,
        LOWER(TRIM(email)) as email,
        TRIM(company) as company,
        CASE 
            WHEN UPPER(plan_type) IN ('FREE', 'BASIC') THEN 'Free'
            WHEN UPPER(plan_type) IN ('PRO', 'PROFESSIONAL') THEN 'Pro'
            WHEN UPPER(plan_type) IN ('BUSINESS', 'BIZ') THEN 'Business'
            WHEN UPPER(plan_type) IN ('ENTERPRISE', 'ENT') THEN 'Enterprise'
            ELSE plan_type
        END as plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_users
