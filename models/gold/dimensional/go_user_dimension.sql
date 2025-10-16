{{ config(
    materialized='table'
) }}

WITH source_users AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        record_status,
        load_date,
        update_date,
        source_system,
        load_timestamp,
        update_timestamp
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type,
        ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
    FROM {{ source('silver', 'si_licenses') }}
    WHERE record_status = 'ACTIVE'
),

user_with_license AS (
    SELECT 
        u.user_id,
        u.user_name,
        u.email,
        u.company,
        u.plan_type,
        u.record_status,
        l.license_type,
        u.load_date,
        u.update_date,
        u.source_system
    FROM source_users u
    LEFT JOIN latest_licenses l ON u.user_id = l.assigned_to_user_id AND l.rn = 1
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_dim_id,
    user_id,
    user_name,
    email as email_address,
    CASE 
        WHEN plan_type = 'Pro' THEN 'Professional'
        WHEN plan_type = 'Basic' THEN 'Basic'
        WHEN plan_type = 'Enterprise' THEN 'Enterprise'
        ELSE 'Standard'
    END as user_type,
    CASE 
        WHEN record_status = 'ACTIVE' THEN 'Active'
        WHEN record_status = 'INACTIVE' THEN 'Inactive'
        WHEN record_status = 'SUSPENDED' THEN 'Suspended'
        ELSE 'Unknown'
    END as account_status,
    COALESCE(license_type, 'No License') as license_type,
    CAST(NULL AS VARCHAR(255)) as department_name,
    CAST(NULL AS VARCHAR(255)) as job_title,
    CAST(NULL AS VARCHAR(255)) as time_zone,
    CAST(NULL AS DATE) as account_creation_date,
    CAST(NULL AS DATE) as last_login_date,
    CAST(NULL AS VARCHAR(255)) as language_preference,
    CAST(NULL AS VARCHAR(255)) as phone_number,
    load_date,
    update_date,
    source_system,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    'ACTIVE' as process_status
FROM user_with_license
