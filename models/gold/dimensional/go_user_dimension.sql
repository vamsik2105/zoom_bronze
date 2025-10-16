{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, created_at, updated_at) VALUES (UUID_STRING(), 'user_dimension_transformation', 'si_users', 'go_user_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}), updated_at = CURRENT_TIMESTAMP() WHERE process_name = 'user_dimension_transformation' AND process_status = 'STARTED'"
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
    FROM {{ ref('si_users') }}
    WHERE record_status = 'ACTIVE'
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type,
        ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
    FROM {{ ref('si_licenses') }}
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
    UUID_STRING() as user_dim_id,
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
    NULL as department_name,
    NULL as job_title,
    NULL as time_zone,
    NULL as account_creation_date,
    NULL as last_login_date,
    NULL as language_preference,
    NULL as phone_number,
    load_date,
    update_date,
    source_system,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    'ACTIVE' as process_status
FROM user_with_license
