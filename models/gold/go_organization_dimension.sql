{{ config(
    materialized='table'
) }}

-- Gold Organization Dimension Table
-- Creates organization dimension from available Silver data

WITH silver_users AS (
    SELECT DISTINCT
        company,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver', 'si_users') }}
    WHERE company IS NOT NULL
      AND record_status = 'ACTIVE'
),

organization_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['company']) }} as organization_dim_id,
        {{ dbt_utils.generate_surrogate_key(['company']) }} as organization_id,
        company as organization_name,
        NULL as industry_classification,    -- Not available in Silver
        NULL as organization_size,          -- Not available in Silver
        NULL as primary_contact_email,      -- Not available in Silver
        NULL as billing_address,            -- Not available in Silver
        NULL as account_manager_name,       -- Not available in Silver
        NULL as contract_start_date,        -- Not available in Silver
        NULL as contract_end_date,          -- Not available in Silver
        NULL as maximum_user_limit,         -- Not available in Silver
        NULL as storage_quota_gb,           -- Not available in Silver
        NULL as security_policy_level,      -- Not available in Silver
        load_date,
        update_date,
        source_system,
        CURRENT_TIMESTAMP() as created_at,
        CURRENT_TIMESTAMP() as updated_at,
        'SUCCESS' as process_status
    FROM silver_users
)

SELECT * FROM organization_dimension
