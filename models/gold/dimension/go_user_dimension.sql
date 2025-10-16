{{ config(
    materialized='table'
) }}

WITH users_base AS (
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
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY update_timestamp DESC) as rn
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
),

licenses_latest AS (
    SELECT
        assigned_to_user_id,
        license_type,
        ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
    FROM {{ source('silver', 'si_licenses') }}
    WHERE record_status = 'ACTIVE'
),

user_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['u.user_id']) }} AS user_dim_id,
        u.user_id,
        u.user_name,
        u.email AS email_address,
        CASE 
            WHEN u.plan_type = 'Pro' THEN 'Professional'
            WHEN u.plan_type = 'Basic' THEN 'Basic'
            WHEN u.plan_type = 'Enterprise' THEN 'Enterprise'
            ELSE 'Standard'
        END AS user_type,
        CASE 
            WHEN u.record_status = 'ACTIVE' THEN 'Active'
            WHEN u.record_status = 'INACTIVE' THEN 'Inactive'
            ELSE 'Unknown'
        END AS account_status,
        COALESCE(l.license_type, 'No License') AS license_type,
        NULL AS department_name,
        NULL AS job_title,
        NULL AS time_zone,
        NULL AS account_creation_date,
        NULL AS last_login_date,
        NULL AS language_preference,
        NULL AS phone_number,
        u.load_date,
        u.update_date,
        u.source_system
    FROM users_base u
    LEFT JOIN licenses_latest l ON u.user_id = l.assigned_to_user_id AND l.rn = 1
    WHERE u.rn = 1
)

SELECT
    user_dim_id::VARCHAR(50) AS user_dim_id,
    user_id::VARCHAR(50) AS user_id,
    user_name::VARCHAR(255) AS user_name,
    email_address::VARCHAR(320) AS email_address,
    user_type::VARCHAR(50) AS user_type,
    account_status::VARCHAR(50) AS account_status,
    license_type::VARCHAR(100) AS license_type,
    department_name::VARCHAR(200) AS department_name,
    job_title::VARCHAR(200) AS job_title,
    time_zone::VARCHAR(50) AS time_zone,
    account_creation_date::DATE AS account_creation_date,
    last_login_date::DATE AS last_login_date,
    language_preference::VARCHAR(50) AS language_preference,
    phone_number::VARCHAR(50) AS phone_number,
    load_date,
    update_date,
    source_system::VARCHAR(100) AS source_system
FROM user_dimension
