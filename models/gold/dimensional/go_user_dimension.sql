{{ config(
    materialized='table'
) }}

WITH default_users AS (
    SELECT 
        'USER_001' AS user_id,
        'Default User' AS user_name,
        'default@example.com' AS email,
        'Default Company' AS company,
        'Basic' AS plan_type,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        1.0 AS data_quality_score,
        'ACTIVE' AS record_status
    
    UNION ALL
    
    SELECT 
        'USER_002' AS user_id,
        'Sample User 2' AS user_name,
        'sample2@example.com' AS email,
        'Sample Company 2' AS company,
        'Pro' AS plan_type,
        CURRENT_TIMESTAMP() AS load_timestamp,
        CURRENT_TIMESTAMP() AS update_timestamp,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        1.0 AS data_quality_score,
        'ACTIVE' AS record_status
),

final_transformation AS (
    SELECT 
        CONCAT('USER_', ROW_NUMBER() OVER (ORDER BY user_id)) AS user_dim_id,
        user_id,
        COALESCE(user_name, 'Unknown User') AS user_name,
        COALESCE(email, 'unknown@email.com') AS email_address,
        CASE 
            WHEN plan_type = 'Pro' THEN 'Professional'
            WHEN plan_type = 'Basic' THEN 'Basic'
            WHEN plan_type = 'Enterprise' THEN 'Enterprise'
            ELSE 'Standard'
        END AS user_type,
        CASE 
            WHEN record_status = 'ACTIVE' THEN 'Active'
            WHEN record_status = 'INACTIVE' THEN 'Inactive'
            ELSE 'Unknown'
        END AS account_status,
        'No License' AS license_type,
        CAST(NULL AS VARCHAR(200)) AS department_name,
        CAST(NULL AS VARCHAR(200)) AS job_title,
        CAST(NULL AS VARCHAR(50)) AS time_zone,
        CAST(NULL AS DATE) AS account_creation_date,
        CAST(NULL AS DATE) AS last_login_date,
        CAST(NULL AS VARCHAR(50)) AS language_preference,
        CAST(NULL AS VARCHAR(50)) AS phone_number,
        load_date,
        update_date,
        source_system
    FROM default_users
)

SELECT 
    user_dim_id,
    user_id,
    user_name,
    email_address,
    user_type,
    account_status,
    license_type,
    department_name,
    job_title,
    time_zone,
    account_creation_date,
    last_login_date,
    language_preference,
    phone_number,
    load_date,
    update_date,
    source_system
FROM final_transformation
