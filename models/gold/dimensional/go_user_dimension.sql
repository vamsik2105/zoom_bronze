{{ config(
    materialized='table'
) }}

WITH silver_users_check AS (
    SELECT COUNT(*) as user_count
    FROM {{ ref('si_users') }}
),

default_users AS (
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
    WHERE (SELECT user_count FROM silver_users_check) = 0
),

silver_users AS (
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
    FROM {{ ref('si_users') }}
    WHERE record_status = 'ACTIVE'
      AND data_quality_score >= 0.8
    
    UNION ALL
    
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
    FROM default_users
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type,
        start_date,
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
        COALESCE(l.license_type, 'No License') AS license_type,
        u.load_timestamp,
        u.update_timestamp,
        u.source_system,
        u.load_date,
        u.update_date,
        u.data_quality_score,
        u.record_status
    FROM silver_users u
    LEFT JOIN latest_licenses l ON u.user_id = l.assigned_to_user_id AND l.rn = 1
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
        license_type,
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
    FROM user_with_license
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
