-- Silver layer licenses table with data quality checks and transformations
-- Transforms bronze licenses data with validation and cleansing

{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, records_processed, records_successful, records_failed, processing_duration_seconds, source_system, target_system, process_type, load_date, update_date) SELECT '{{ invocation_id }}_si_licenses', 'si_licenses', CURRENT_TIMESTAMP, 'RUNNING', 0, 0, 0, 0, 'BRONZE', 'SILVER', 'ETL', CURRENT_DATE, CURRENT_DATE WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP, status = 'SUCCESS', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP), update_date = CURRENT_DATE WHERE execution_id = '{{ invocation_id }}_si_licenses' AND '{{ this.name }}' != 'si_process_audit'"
) }}

WITH bronze_licenses AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('bronze', 'bz_licenses') }}
),

-- Data quality validation
validated_licenses AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN license_id IS NULL THEN 1 ELSE 0 END as null_license_id,
        CASE WHEN start_date IS NULL THEN 1 ELSE 0 END as null_start_date,
        
        -- Domain validation
        CASE WHEN license_type IS NOT NULL AND license_type NOT IN ('Pro','Business','Enterprise','Education') 
             THEN 1 ELSE 0 END as invalid_license_type,
        
        -- Logical validation
        CASE WHEN end_date IS NOT NULL AND start_date IS NOT NULL AND end_date <= start_date 
             THEN 1 ELSE 0 END as invalid_date_range
    FROM bronze_licenses
),

-- Clean and transform data
cleaned_licenses AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(TRIM(license_type)) = 'PRO' THEN 'Pro'
            WHEN UPPER(TRIM(license_type)) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(TRIM(license_type)) = 'ENTERPRISE' THEN 'Enterprise'
            WHEN UPPER(TRIM(license_type)) = 'EDUCATION' THEN 'Education'
            ELSE license_type
        END as license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        
        -- Data quality flags
        null_license_id + null_start_date + invalid_license_type + invalid_date_range as error_count,
        
        -- Record status
        CASE 
            WHEN null_license_id = 1 OR null_start_date = 1 OR invalid_date_range = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_licenses
),

-- Calculate data quality score
final_licenses AS (
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
        
        -- Data quality score calculation
        CASE 
            WHEN error_count = 0 THEN 1.0
            WHEN error_count = 1 THEN 0.8
            WHEN error_count = 2 THEN 0.6
            WHEN error_count = 3 THEN 0.4
            WHEN error_count = 4 THEN 0.2
            ELSE 0.0
        END as data_quality_score,
        
        record_status
    FROM cleaned_licenses
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_licenses
