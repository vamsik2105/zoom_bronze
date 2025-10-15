{{ config(
    materialized='table'
) }}

SELECT 
    'USER_001' AS user_dim_id,
    'U001' AS user_id,
    'Sample User' AS user_name,
    'user@example.com' AS email_address,
    'Professional' AS user_type,
    'Active' AS account_status,
    'Standard License' AS license_type,
    NULL AS department_name,
    NULL AS job_title,
    NULL AS time_zone,
    NULL AS account_creation_date,
    NULL AS last_login_date,
    NULL AS language_preference,
    NULL AS phone_number,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'SILVER' AS source_system
