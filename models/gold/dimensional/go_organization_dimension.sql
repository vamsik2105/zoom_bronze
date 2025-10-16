{{ config(
    materialized='table'
) }}

WITH organization_data AS (
    SELECT DISTINCT
        company,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver', 'si_users') }}
    WHERE company IS NOT NULL
    AND record_status = 'ACTIVE'
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['company']) }} as organization_dim_id,
    company as organization_id,
    company as organization_name,
    CAST(NULL AS VARCHAR(255)) as industry_classification,
    CAST(NULL AS VARCHAR(255)) as organization_size,
    CAST(NULL AS VARCHAR(255)) as primary_contact_email,
    CAST(NULL AS VARCHAR(255)) as billing_address,
    CAST(NULL AS VARCHAR(255)) as account_manager_name,
    CAST(NULL AS DATE) as contract_start_date,
    CAST(NULL AS DATE) as contract_end_date,
    CAST(NULL AS NUMBER) as maximum_user_limit,
    CAST(NULL AS NUMBER) as storage_quota_gb,
    CAST(NULL AS VARCHAR(255)) as security_policy_level,
    load_date,
    update_date,
    source_system,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    'ACTIVE' as process_status
FROM organization_data
