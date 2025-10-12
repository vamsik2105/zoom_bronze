{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'si_users', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED'",
    post_hook="UPDATE {{ ref('si_audit_log') }} SET status = 'COMPLETED', processing_time = 10 WHERE source_table = 'si_users' AND status = 'STARTED'"
) }}

-- Transform bronze users data to silver layer with data quality checks
WITH bronze_users AS (
    SELECT *
    FROM {{ source('bronze', 'bz_users') }}
),

-- Data quality validation
validated_users AS (
    SELECT 
        *,
        CASE 
            WHEN user_id IS NULL THEN 'NULL_USER_ID'
            WHEN email IS NULL THEN 'NULL_EMAIL'
            WHEN plan_type NOT IN ('Free', 'Pro', 'Business', 'Enterprise') THEN 'INVALID_PLAN_TYPE'
            ELSE 'VALID'
        END AS validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN user_id IS NOT NULL 
                AND email IS NOT NULL 
                AND plan_type IN ('Free', 'Pro', 'Business', 'Enterprise')
                AND user_name IS NOT NULL
            THEN 1.0
            WHEN user_id IS NOT NULL AND email IS NOT NULL
            THEN 0.75
            WHEN user_id IS NOT NULL
            THEN 0.5
            ELSE 0.0
        END AS data_quality_score
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_users
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_users
