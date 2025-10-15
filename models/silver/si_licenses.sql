{{ config(
    materialized='incremental',
    unique_key='license_id',
    on_schema_change='fail',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_licenses']) }}', 'si_licenses_transformation', CURRENT_TIMESTAMP(), 'STARTED', 'Bronze', 'Silver', 'ETL', CURRENT_DATE(), CURRENT_DATE() WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_licenses']) }}' AND '{{ this.name }}' != 'si_process_audit'"
) }}

-- Silver Licenses Transformation with Data Quality Checks
WITH bronze_licenses AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY license_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     CASE WHEN license_type IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN start_date IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN end_date IS NOT NULL THEN 1 ELSE 0 END DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_licenses') }}
    WHERE license_id IS NOT NULL
),

deduped_licenses AS (
    SELECT *
    FROM bronze_licenses
    WHERE row_rank = 1
),

data_quality_checks AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(TRIM(license_type)) IN ('PRO', 'BUSINESS', 'ENTERPRISE', 'EDUCATION') 
            THEN UPPER(TRIM(license_type))
            ELSE 'PRO'
        END AS license_type_clean,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Data Quality Score Calculation
        (
            CASE WHEN license_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN UPPER(TRIM(license_type)) IN ('PRO', 'BUSINESS', 'ENTERPRISE', 'EDUCATION') THEN 0.25 ELSE 0 END +
            CASE WHEN start_date IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN end_date IS NOT NULL AND end_date > start_date THEN 0.25 ELSE 0 END
        ) AS data_quality_score,
        -- Record Status
        CASE 
            WHEN license_id IS NULL THEN 'ERROR'
            WHEN license_type IS NULL OR TRIM(license_type) = '' THEN 'ERROR'
            WHEN start_date IS NULL OR end_date IS NULL THEN 'ERROR'
            WHEN end_date <= start_date THEN 'ERROR'
            ELSE 'ACTIVE'
        END AS record_status
    FROM deduped_licenses
),

final_licenses AS (
    SELECT 
        license_id,
        license_type_clean AS license_type,
        assigned_to_user_id,
        start_date,
        end_date,
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
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM final_licenses

{% if is_incremental() %}
    WHERE update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
