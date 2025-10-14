{{ config(
    materialized='table'
) }}

WITH source_users AS (
    SELECT 
        user_id,
        user_name,
        email,
        plan_type,
        record_status,
        load_date,
        update_date,
        source_system
    FROM SILVER.si_users
    WHERE record_status = 'ACTIVE'
),

source_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type,
        start_date,
        ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
    FROM SILVER.si_licenses
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type
    FROM source_licenses
    WHERE rn = 1
),

final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['u.user_id']) }} as user_dim_id,
        u.user_id,
        u.user_name,
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
    FROM source_users u
    LEFT JOIN latest_licenses l ON u.user_id = l.assigned_to_user_id
)

SELECT * FROM final
