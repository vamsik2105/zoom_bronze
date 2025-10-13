{{ config(
    materialized='table'
) }}

WITH bronze_licenses AS (
    SELECT *
    FROM BRONZE.bz_licenses
),

-- Data Quality Validations
validated_licenses AS (
    SELECT *,
        CASE 
            WHEN license_id IS NULL THEN 'Missing license_id'
            WHEN license_type IS NULL THEN 'Missing license_type'
            WHEN license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 'Invalid license_type'
            WHEN start_date IS NULL THEN 'Missing start_date'
            WHEN end_date IS NULL THEN 'Missing end_date'
            WHEN end_date <= start_date THEN 'Invalid date range'
            ELSE NULL
        END AS validation_error
    FROM bronze_licenses
),

-- Clean and Transform Data
transformed_licenses AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(license_type) = 'PRO' THEN 'Pro'
            WHEN UPPER(license_type) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(license_type) = 'ENTERPRISE' THEN 'Enterprise'
            WHEN UPPER(license_type) = 'EDUCATION' THEN 'Education'
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
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
    FROM validated_licenses
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
    CASE 
        WHEN record_status = 'error' THEN 0.0
        ELSE (
            CASE WHEN load_timestamp IS NOT NULL THEN 0.25 ELSE 0.0 END +
            CASE WHEN update_timestamp IS NOT NULL THEN 0.25 ELSE 0.0 END +
            CASE WHEN source_system IS NOT NULL THEN 0.25 ELSE 0.0 END +
            0.25 -- Base score for valid record
        )
    END as data_quality_score,
    record_status
FROM transformed_licenses
WHERE validation_error IS NULL

UNION ALL

-- Error Records for Audit
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
    0.0 as data_quality_score,
    'error' as record_status
FROM transformed_licenses
WHERE validation_error IS NOT NULL
