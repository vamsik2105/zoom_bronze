{{ config(
    materialized='table'
) }}

WITH silver_users_check AS (
    SELECT COUNT(*) as user_count
    FROM {{ ref('si_users') }}
),

default_organizations AS (
    SELECT DISTINCT
        'Default Organization' AS company,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
    WHERE (SELECT user_count FROM silver_users_check) = 0
),

silver_organizations AS (
    SELECT DISTINCT
        company,
        source_system,
        load_date,
        update_date
    FROM {{ ref('si_users') }}
    WHERE company IS NOT NULL
      AND record_status = 'ACTIVE'
      AND data_quality_score >= 0.8
    
    UNION ALL
    
    SELECT 
        company,
        source_system,
        load_date,
        update_date
    FROM default_organizations
),

final_transformation AS (
    SELECT 
        CONCAT('ORG_', ROW_NUMBER() OVER (ORDER BY company)) AS organization_dim_id,
        CONCAT('ORG_ID_', ROW_NUMBER() OVER (ORDER BY company)) AS organization_id,
        company AS organization_name,
        CAST(NULL AS VARCHAR(200)) AS industry_classification,
        CAST(NULL AS VARCHAR(50)) AS organization_size,
        CAST(NULL AS VARCHAR(320)) AS primary_contact_email,
        CAST(NULL AS VARCHAR(1000)) AS billing_address,
        CAST(NULL AS VARCHAR(255)) AS account_manager_name,
        CAST(NULL AS DATE) AS contract_start_date,
        CAST(NULL AS DATE) AS contract_end_date,
        CAST(NULL AS NUMBER) AS maximum_user_limit,
        CAST(NULL AS NUMBER) AS storage_quota_gb,
        CAST(NULL AS VARCHAR(100)) AS security_policy_level,
        load_date,
        update_date,
        source_system
    FROM silver_organizations
)

SELECT 
    organization_dim_id,
    organization_id,
    organization_name,
    industry_classification,
    organization_size,
    primary_contact_email,
    billing_address,
    account_manager_name,
    contract_start_date,
    contract_end_date,
    maximum_user_limit,
    storage_quota_gb,
    security_policy_level,
    load_date,
    update_date,
    source_system
FROM final_transformation
