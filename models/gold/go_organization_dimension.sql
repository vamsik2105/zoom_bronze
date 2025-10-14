{{ config(
    materialized='table'
) }}

-- Gold Organization Dimension Table
-- Note: Since organization table is not available in Silver, creating default organization
WITH default_organization AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(["'DEFAULT_ORG'"]) }} AS organization_dim_id,
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
