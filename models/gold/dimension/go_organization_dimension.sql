{{ config(
    materialized='table'
) }}

WITH organization_base AS (
    SELECT DISTINCT
        company AS organization_name,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver', 'si_users') }}
    WHERE company IS NOT NULL
      AND record_status = 'ACTIVE'
),

organization_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['organization_name']) }} AS organization_dim_id,
        {{ dbt_utils.generate_surrogate_key(['organization_name']) }} AS organization_id,
        organization_name,
        NULL AS industry_classification,
        NULL AS organization_size,
        NULL AS primary_contact_email,
        NULL AS billing_address,
        NULL AS account_manager_name,
        NULL AS contract_start_date,
        NULL AS contract_end_date,
        NULL AS maximum_user_limit,
        NULL AS storage_quota_gb,
        NULL AS security_policy_level,
        load_date,
        update_date,
        source_system
    FROM organization_base
)

SELECT
    organization_dim_id::VARCHAR(50) AS organization_dim_id,
    organization_id::VARCHAR(50) AS organization_id,
    organization_name::VARCHAR(500) AS organization_name,
    industry_classification::VARCHAR(200) AS industry_classification,
    organization_size::VARCHAR(50) AS organization_size,
    primary_contact_email::VARCHAR(320) AS primary_contact_email,
    billing_address::VARCHAR(1000) AS billing_address,
    account_manager_name::VARCHAR(255) AS account_manager_name,
    contract_start_date::DATE AS contract_start_date,
    contract_end_date::DATE AS contract_end_date,
    maximum_user_limit,
    storage_quota_gb,
    security_policy_level::VARCHAR(100) AS security_policy_level,
    load_date,
    update_date,
    source_system::VARCHAR(100) AS source_system
FROM organization_dimension
