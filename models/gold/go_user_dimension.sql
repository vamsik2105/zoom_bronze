{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed, load_date) VALUES ('{{ invocation_id }}', 'go_user_dimension', 'DBT_MODEL', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', 'DBT_CLOUD', CURRENT_DATE())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), records_failed = 0, update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_user_dimension'"
) }}

-- Gold User Dimension Table
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
    WHERE record_status IS NOT NULL
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
),

latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type
    FROM silver_licenses
    WHERE rn = 1
),

user_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['su.user_id']) }} AS user_dim_id,
        su.user_id,
        su.user_name,
        su.email AS email_address,
        CASE 
            WHEN su.plan_type = 'Pro' THEN 'Professional'
            WHEN su.plan_type = 'Basic' THEN 'Basic'
            WHEN su.plan_type = 'Enterprise' THEN 'Enterprise'
            ELSE 'Standard'
        END AS user_type,
        CASE 
            WHEN su.record_status = 'ACTIVE' THEN 'Active'
            WHEN su.record_status = 'INACTIVE' THEN 'Inactive'
            ELSE 'Unknown'
        END AS account_status,
        COALESCE(ll.license_type, 'No License') AS license_type,
        NULL AS department_name,
        NULL AS job_title,
        NULL AS time_zone,
        NULL AS account_creation_date,
        NULL AS last_login_date,
        NULL AS language_preference,
        NULL AS phone_number,
        su.load_date,
        su.update_date,
        su.source_system
    FROM silver_users su
    LEFT JOIN latest_licenses ll ON su.user_id = ll.assigned_to_user_id
)

SELECT * FROM user_dimension
