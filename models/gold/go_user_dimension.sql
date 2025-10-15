{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) SELECT '{{ invocation_id }}_user_dim', 'User Dimension Transform', 'Dimension Build', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE() WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}_user_dim' AND status = 'STARTED' AND '{{ this.name }}' != 'go_process_audit'"
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
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
        AND data_quality_score >= 0.7
),

silver_licenses AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        ROW_NUMBER() OVER (PARTITION BY assigned_to_user_id ORDER BY start_date DESC) as rn
    FROM {{ source('silver', 'si_licenses') }}
    WHERE record_status = 'ACTIVE'
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type
    FROM silver_licenses
    WHERE rn = 1
),

user_dimension_prep AS (
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
        CAST(NULL AS VARCHAR(200)) AS department_name,
        CAST(NULL AS VARCHAR(200)) AS job_title,
        CAST(NULL AS VARCHAR(50)) AS time_zone,
        CAST(NULL AS DATE) AS account_creation_date,
        CAST(NULL AS DATE) AS last_login_date,
        CAST(NULL AS VARCHAR(50)) AS language_preference,
        CAST(NULL AS VARCHAR(50)) AS phone_number,
        u.load_date,
        u.update_date,
        u.source_system
    FROM silver_users u
    LEFT JOIN latest_licenses l ON u.user_id = l.assigned_to_user_id
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
FROM user_dimension_prep
