{{ config(
    materialized='table',
    pre_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date, update_date, source_system) VALUES (UUID_STRING(), 'go_user_dimension_transform', 'si_users', 'go_user_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_DATE(), CURRENT_DATE(), 'DBT_TRANSFORM'){% endif %}",
    post_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date, update_date, source_system) VALUES (UUID_STRING(), 'go_user_dimension_transform', 'si_users', 'go_user_dimension', 'COMPLETED', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), (SELECT COUNT(*) FROM {{ this }}), NULL, CURRENT_DATE(), CURRENT_DATE(), 'DBT_TRANSFORM'){% endif %}"
) }}

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
    FROM {{ ref('si_users') }}
    WHERE record_status = 'ACTIVE'
      AND data_quality_score >= 0.8
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
        l.license_type,
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
        UUID_STRING() AS user_dim_id,
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
        COALESCE(license_type, 'No License') AS license_type,
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
