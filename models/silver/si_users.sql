{{ config(
    materialized='incremental',
    unique_key='user_id',
    on_schema_change='fail',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_users']) }}', 'si_users_transformation', CURRENT_TIMESTAMP(), 'STARTED', 'Bronze', 'Silver', 'ETL', CURRENT_DATE(), CURRENT_DATE() WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_users']) }}' AND '{{ this.name }}' != 'si_process_audit'"
) }}

-- Silver Users Transformation with Data Quality Checks
WITH bronze_users AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     CASE WHEN user_name IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN email IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN company IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN plan_type IS NOT NULL THEN 1 ELSE 0 END DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_users') }}
    WHERE user_id IS NOT NULL
),

deduped_users AS (
    SELECT *
    FROM bronze_users
    WHERE row_rank = 1
),

data_quality_checks AS (
    SELECT 
        user_id,
        TRIM(user_name) AS user_name_clean,
        LOWER(TRIM(email)) AS email_clean,
        TRIM(company) AS company_clean,
        CASE 
            WHEN UPPER(TRIM(plan_type)) IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') 
            THEN UPPER(TRIM(plan_type))
            ELSE 'FREE'
        END AS plan_type_clean,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Data Quality Score Calculation
        (
            CASE WHEN user_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN TRIM(user_name) IS NOT NULL AND TRIM(user_name) != '' THEN 0.25 ELSE 0 END +
            CASE WHEN email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN 0.25 ELSE 0 END +
            CASE WHEN UPPER(TRIM(plan_type)) IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') THEN 0.25 ELSE 0 END
        ) AS data_quality_score,
        -- Record Status
        CASE 
            WHEN user_id IS NULL THEN 'ERROR'
            WHEN TRIM(user_name) IS NULL OR TRIM(user_name) = '' THEN 'ERROR'
            WHEN NOT (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'ERROR'
            ELSE 'ACTIVE'
        END AS record_status
    FROM deduped_users
),

final_users AS (
    SELECT 
        user_id,
        user_name_clean AS user_name,
        email_clean AS email,
        company_clean AS company,
        plan_type_clean AS plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'ACTIVE'  -- Only pass clean records to Silver
)

SELECT 
    user_id,
    user_name,
    email,
    company,
    plan_type,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM final_users

{% if is_incremental() %}
    WHERE update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
