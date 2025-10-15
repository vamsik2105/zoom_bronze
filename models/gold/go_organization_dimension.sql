{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) SELECT '{{ invocation_id }}_org_dim', 'Organization Dimension Transform', 'Dimension Build', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE() WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}_org_dim' AND status = 'STARTED' AND '{{ this.name }}' != 'go_process_audit'"
) }}

WITH organization_data AS (
    SELECT DISTINCT
        company,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver', 'si_users') }}
    WHERE company IS NOT NULL
        AND TRIM(company) != ''
        AND record_status = 'ACTIVE'
),

organization_dimension_prep AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['company']) }} AS organization_dim_id,
        {{ dbt_utils.generate_surrogate_key(['company']) }} AS organization_id,
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
    FROM organization_data
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
FROM organization_dimension_prep
