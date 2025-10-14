{{ config(
    materialized='table'
) }}

WITH final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['1']) }} as organization_dim_id,
        'ORG_001' as organization_id,
        'Default Organization' as organization_name,
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
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'SYSTEM' as source_system
)

SELECT * FROM final
