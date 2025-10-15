{{ config(
    materialized='table'
) }}

SELECT 
    MD5(CAST(COALESCE(CAST(user_id AS VARCHAR), '_dbt_utils_surrogate_key_null_') AS VARCHAR)) AS user_dim_id,
    user_id,
    COALESCE(user_name, 'Unknown User') AS user_name,
    email AS email_address,
    CASE 
        WHEN plan_type = 'Pro' THEN 'Professional'
        WHEN plan_type = 'Basic' THEN 'Basic'
        WHEN plan_type = 'Enterprise' THEN 'Enterprise'
        ELSE 'Standard'
    END AS user_type,
    CASE 
        WHEN record_status = 'ACTIVE' THEN 'Active'
        WHEN record_status = 'INACTIVE' THEN 'Inactive'
        WHEN record_status = 'SUSPENDED' THEN 'Suspended'
        ELSE 'Unknown'
    END AS account_status,
    'Standard License' AS license_type,
    NULL AS department_name,
    NULL AS job_title,
    NULL AS time_zone,
    NULL AS account_creation_date,
    NULL AS last_login_date,
    NULL AS language_preference,
    NULL AS phone_number,
    load_date,
    update_date,
    source_system
FROM {{ source('silver_layer', 'si_users') }}
WHERE record_status = 'ACTIVE'
