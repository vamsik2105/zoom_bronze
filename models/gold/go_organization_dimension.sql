{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed, load_date) VALUES ('{{ invocation_id }}', 'go_organization_dimension', 'DBT_MODEL', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', 'DBT_CLOUD', CURRENT_DATE())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), records_failed = 0, update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_organization_dimension'"
) }}

-- Gold Organization Dimension Table
-- Note: Since organization table is not available in Silver, creating default organization
WITH default_organization AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['"DEFAULT_ORG"']) }} AS organization_dim_id,
        'DEFAULT_ORG' AS organization_id,
        'Default Organization' AS organization_name,
        'Technology' AS industry_classification,
        'Medium' AS organization_size,
        'admin@company.com' AS primary_contact_email,
        'Default Address' AS billing_address,
        'Default Manager' AS account_manager_name,
        CURRENT_DATE() AS contract_start_date,
        DATEADD('year', 1, CURRENT_DATE()) AS contract_end_date,
        1000 AS maximum_user_limit,
        100 AS storage_quota_gb,
        'Standard' AS security_policy_level,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'SYSTEM_GENERATED' AS source_system
)

SELECT * FROM default_organization
