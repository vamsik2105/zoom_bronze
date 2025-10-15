{{ config(
    materialized='table',
    pre_hook="INSERT INTO GOLD.go_process_audit (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) VALUES ('{{ invocation_id }}', 'go_organization_dimension', 'TRANSFORMATION', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE())",
    post_hook="UPDATE GOLD.go_process_audit SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM GOLD.go_organization_dimension), processing_duration_seconds = 10 WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_organization_dimension'"
) }}

-- Gold Organization Dimension Table
-- Creates organization dimension from available Silver data

WITH silver_users AS (
    SELECT DISTINCT
        company,
        source_system,
        load_date,
        update_date
    FROM SILVER.si_users
    WHERE company IS NOT NULL
      AND record_status = 'ACTIVE'
),

organization_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['company']) }} as organization_dim_id,
        {{ dbt_utils.generate_surrogate_key(['company']) }} as organization_id,
        company as organization_name,
        NULL as industry_classification,
        NULL as organization_size,
        NULL as primary_contact_email,
        NULL as billing_address,
        NULL as account_manager_name,
        NULL as contract_start_date,
        NULL as contract_end_date,
        NULL as maximum_user_limit,
        NULL as storage_quota_gb,
        NULL as security_policy_level,
        load_date,
        update_date,
        source_system
    FROM silver_users
)

SELECT * FROM organization_dimension
