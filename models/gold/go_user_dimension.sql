{{ config(
    materialized='table'
) }}

-- Gold User Dimension Table
-- Transforms Silver user data into a comprehensive user dimension for analytics

WITH silver_users AS (
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
    FROM SILVER.si_users
    WHERE record_status = 'ACTIVE'
      AND data_quality_score >= 0.7
),

silver_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type,
        start_date,
        end_date,
        ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
    FROM SILVER.si_licenses
    WHERE record_status = 'ACTIVE'
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type
    FROM silver_licenses
    WHERE rn = 1
),

user_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['u.user_id']) }} as user_dim_id,
        u.user_id,
        COALESCE(u.user_name, 'Unknown User') as user_name,
        u.email as email_address,
        CASE 
            WHEN u.plan_type = 'Pro' THEN 'Professional'
            WHEN u.plan_type = 'Basic' THEN 'Basic'
            WHEN u.plan_type = 'Enterprise' THEN 'Enterprise'
            ELSE 'Standard'
        END as user_type,
        CASE 
            WHEN u.record_status = 'ACTIVE' THEN 'Active'
            WHEN u.record_status = 'INACTIVE' THEN 'Inactive'
            WHEN u.record_status = 'SUSPENDED' THEN 'Suspended'
            ELSE 'Unknown'
        END as account_status,
        COALESCE(l.license_type, 'No License') as license_type,
        NULL as department_name,
        NULL as job_title,
        NULL as time_zone,
        NULL as account_creation_date,
        NULL as last_login_date,
        NULL as language_preference,
        NULL as phone_number,
        u.load_date,
        u.update_date,
        u.source_system
    FROM silver_users u
    LEFT JOIN latest_licenses l ON u.user_id = l.assigned_to_user_id
)

SELECT * FROM user_dimension
