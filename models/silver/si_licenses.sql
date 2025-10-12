{{
  config(
    materialized='table'
  )
}}

-- Transform bronze licenses to silver licenses with data quality checks
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

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN license_id IS NULL OR license_id = '' THEN 'INVALID_LICENSE_ID'
            WHEN license_type IS NULL OR license_type = '' THEN 'MISSING_LICENSE_TYPE'
            WHEN license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 'INVALID_LICENSE_TYPE'
            WHEN start_date IS NULL THEN 'MISSING_START_DATE'
            WHEN end_date IS NULL THEN 'MISSING_END_DATE'
            WHEN end_date <= start_date THEN 'INVALID_DATE_RANGE'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN license_id IS NULL OR license_id = '' THEN 0.0
            WHEN license_type IS NULL OR license_type = '' THEN 0.3
            WHEN start_date IS NULL OR end_date IS NULL THEN 0.5
            WHEN end_date <= start_date THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_licenses
),

cleaned_licenses AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(license_type) IN ('PRO', 'PROFESSIONAL') THEN 'Pro'
            WHEN UPPER(license_type) IN ('BUSINESS', 'BIZ') THEN 'Business'
            WHEN UPPER(license_type) IN ('ENTERPRISE', 'ENT') THEN 'Enterprise'
            WHEN UPPER(license_type) IN ('EDUCATION', 'EDU') THEN 'Education'
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_licenses
