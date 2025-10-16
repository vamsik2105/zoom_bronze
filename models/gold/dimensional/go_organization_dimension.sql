{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, created_at, updated_at) VALUES (UUID_STRING(), 'organization_dimension_transformation', 'derived', 'go_organization_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}), updated_at = CURRENT_TIMESTAMP() WHERE process_name = 'organization_dimension_transformation' AND process_status = 'STARTED'"
) }}

WITH organization_data AS (
    SELECT DISTINCT
        company,
        source_system,
        load_date,
        update_date
    FROM {{ ref('si_users') }}
    WHERE company IS NOT NULL
    AND record_status = 'ACTIVE'
)

SELECT 
    UUID_STRING() as organization_dim_id,
    company as organization_id,
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
    source_system,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    'ACTIVE' as process_status
FROM organization_data
