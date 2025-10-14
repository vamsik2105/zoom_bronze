{{ config(
    materialized='table',
    unique_key='license_id'
) }}

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

-- Data quality validation
validated_licenses AS (
    SELECT 
        *,
        CASE 
            WHEN license_id IS NULL THEN 'NULL_LICENSE_ID'
            WHEN license_type IS NULL THEN 'NULL_LICENSE_TYPE'
            WHEN license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 'INVALID_LICENSE_TYPE'
            WHEN start_date IS NULL THEN 'NULL_START_DATE'
            WHEN end_date IS NULL THEN 'NULL_END_DATE'
            WHEN end_date <= start_date THEN 'INVALID_DATE_RANGE'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_licenses
),

-- Clean and transform valid records
clean_licenses AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(license_type) = 'PRO' THEN 'Pro'
            WHEN UPPER(license_type) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(license_type) = 'ENTERPRISE' THEN 'Enterprise'
            WHEN UPPER(license_type) = 'EDUCATION' THEN 'Education'
            ELSE license_type
        END AS license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        CASE 
            WHEN license_id IS NOT NULL AND license_type IS NOT NULL 
                 AND start_date IS NOT NULL AND end_date IS NOT NULL 
                 AND end_date > start_date THEN 1.0
            ELSE 0.5
        END AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_licenses
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_licenses
