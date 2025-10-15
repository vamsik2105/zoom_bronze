{{
    config(
        materialized='incremental',
        unique_key='user_id',
        on_schema_change='fail',
        pre_hook="
            {% if this.name != 'si_process_audit' %}
                INSERT INTO {{ ref('si_process_audit') }} (
                    execution_id, pipeline_name, start_time, status, source_system, target_system, 
                    process_type, user_executed, server_name, load_date, update_date
                )
                VALUES (
                    '{{ dbt_utils.generate_surrogate_key([this.name, run_started_at]) }}',
                    '{{ this.name }}',
                    '{{ run_started_at }}',
                    'RUNNING',
                    'BRONZE',
                    'SILVER',
                    'ETL',
                    'DBT_SYSTEM',
                    'DBT_CLOUD',
                    CURRENT_DATE,
                    CURRENT_DATE
                )
            {% endif %}
        ",
        post_hook="
            {% if this.name != 'si_process_audit' %}
                UPDATE {{ ref('si_process_audit') }}
                SET 
                    end_time = CURRENT_TIMESTAMP,
                    status = 'SUCCESS',
                    records_processed = (SELECT COUNT(*) FROM {{ this }}),
                    records_successful = (SELECT COUNT(*) FROM {{ this }} WHERE record_status = 'active'),
                    records_failed = (SELECT COUNT(*) FROM {{ this }} WHERE record_status = 'error'),
                    processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP),
                    update_date = CURRENT_DATE
                WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([this.name, run_started_at]) }}'
            {% endif %}
        "
    )
}}

-- Silver Users Transformation with Data Quality Checks
WITH source_data AS (
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
                     (CASE WHEN user_name IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN email IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN company IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN plan_type IS NOT NULL THEN 1 ELSE 0 END) DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_users') }}
    WHERE user_id IS NOT NULL
    
    {% if is_incremental() %}
        AND update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
    {% endif %}
),

data_quality_checks AS (
    SELECT 
        *,
        -- Email validation
        CASE 
            WHEN email IS NULL OR TRIM(email) = '' THEN 0
            WHEN REGEXP_LIKE(LOWER(TRIM(email)), '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$') THEN 1
            ELSE 0
        END AS email_valid,
        
        -- Plan type validation
        CASE 
            WHEN UPPER(TRIM(plan_type)) IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') THEN 1
            ELSE 0
        END AS plan_type_valid,
        
        -- Completeness check
        CASE 
            WHEN user_id IS NOT NULL AND TRIM(user_name) IS NOT NULL AND TRIM(user_name) != '' 
                 AND email IS NOT NULL AND TRIM(email) != '' THEN 1
            ELSE 0
        END AS completeness_check
    FROM source_data
    WHERE row_rank = 1
),

final_data AS (
    SELECT 
        user_id,
        CASE 
            WHEN TRIM(user_name) = '' OR user_name IS NULL THEN '000'
            ELSE TRIM(user_name)
        END AS user_name,
        CASE 
            WHEN TRIM(email) = '' OR email IS NULL THEN '000'
            ELSE LOWER(TRIM(email))
        END AS email,
        CASE 
            WHEN TRIM(company) = '' OR company IS NULL THEN '000'
            ELSE TRIM(company)
        END AS company,
        CASE 
            WHEN UPPER(TRIM(plan_type)) IN ('FREE', 'PRO', 'BUSINESS', 'ENTERPRISE') THEN UPPER(TRIM(plan_type))
            ELSE 'FREE'
        END AS plan_type,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        ROUND((email_valid + plan_type_valid + completeness_check) / 3.0, 2) AS data_quality_score,
        CASE 
            WHEN email_valid = 1 AND plan_type_valid = 1 AND completeness_check = 1 THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM data_quality_checks
)

SELECT * FROM final_data
WHERE record_status = 'active'  -- Only include valid records in Silver layer
