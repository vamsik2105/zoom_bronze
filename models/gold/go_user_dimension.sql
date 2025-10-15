{{ config(
    materialized='table'
) }}

-- User Dimension transformation from Silver to Gold
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
    FROM {{ source('silver_schema', 'si_users') }}
    WHERE record_status = 'ACTIVE'
      AND COALESCE(data_quality_score, 0) >= 0.7
),

silver_licenses AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        record_status,
        ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
    FROM {{ source('silver_schema', 'si_licenses') }}
    WHERE record_status = 'ACTIVE'
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type
    FROM silver_licenses
    WHERE rn = 1
),

user_dimension_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['u.user_id']) }} AS user_dim_id,
        u.user_id,
        COALESCE(u.user_name, 'Unknown User') AS user_name,
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
            WHEN u.record_status = 'SUSPENDED' THEN 'Suspended'
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
    FROM silver_users u
    LEFT JOIN latest_licenses l ON u.user_id = l.assigned_to_user_id
)

SELECT * FROM user_dimension_final
