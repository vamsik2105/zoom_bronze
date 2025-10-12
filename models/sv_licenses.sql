-- =====================================================
-- SILVER LICENSES MODEL
-- =====================================================

{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('sv_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date, records_processed, records_successful, records_failed, processing_duration_seconds) VALUES ('{{ invocation_id }}', 'sv_licenses', CURRENT_TIMESTAMP(), 'RUNNING', 'BRONZE', 'SILVER', 'ETL', CURRENT_DATE(), CURRENT_DATE(), 0, 0, 0, 0)",
    post_hook="UPDATE {{ ref('sv_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'SUCCESS', records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'sv_licenses'"
) }}

WITH bronze_licenses AS (
    SELECT *
    FROM {{ source('bronze', 'bz_licenses') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN license_id IS NULL THEN 0 ELSE 1 END as license_id_check,
        CASE WHEN license_type IS NULL THEN 0 ELSE 1 END as license_type_check,
        CASE WHEN start_date IS NULL THEN 0 ELSE 1 END as start_date_check,
        CASE WHEN end_date IS NULL THEN 0 ELSE 1 END as end_date_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Domain checks
        CASE WHEN license_type IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 1 ELSE 0 END as license_type_domain_check,
        
        -- Logic checks
        CASE WHEN end_date > start_date THEN 1 ELSE 0 END as date_logic_check
    FROM bronze_licenses
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (license_id_check + license_type_check + start_date_check + end_date_check + 
             source_system_check + license_type_domain_check + date_logic_check) / 7.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN license_id IS NULL OR license_type IS NULL OR start_date IS NULL OR end_date IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 'ERROR'
            WHEN end_date <= start_date THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_licenses AS (
    SELECT 
        license_id,
        CASE 
            WHEN license_type IN ('Pro', 'Business', 'Enterprise', 'Education') THEN license_type
            ELSE 'Pro'
        END as license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        record_status
    FROM quality_scored
    WHERE record_status = 'ACTIVE'
)

SELECT * FROM final_licenses
