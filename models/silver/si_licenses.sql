{{ config(
    materialized='table'
) }}

-- Licenses Silver Layer Transformation
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
    FROM BRONZE.bz_licenses
    WHERE load_timestamp IS NOT NULL
),

validated_licenses AS (
    SELECT *,
        CASE 
            WHEN license_id IS NULL OR TRIM(license_id) = '' THEN 'Missing license_id'
            WHEN license_type IS NULL OR TRIM(license_type) = '' THEN 'Missing license_type'
            WHEN UPPER(TRIM(license_type)) NOT IN ('PRO', 'BUSINESS', 'ENTERPRISE', 'EDUCATION') THEN 'Invalid license_type'
            WHEN start_date IS NULL THEN 'Missing start_date'
            WHEN end_date IS NULL THEN 'Missing end_date'
            WHEN end_date <= start_date THEN 'Invalid date range'
            ELSE NULL
        END AS validation_error
    FROM bronze_licenses
),

transformed_licenses AS (
    SELECT 
        TRIM(license_id) as license_id,
        CASE 
            WHEN UPPER(TRIM(license_type)) = 'PRO' THEN 'Pro'
            WHEN UPPER(TRIM(license_type)) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(TRIM(license_type)) = 'ENTERPRISE' THEN 'Enterprise'
            WHEN UPPER(TRIM(license_type)) = 'EDUCATION' THEN 'Education'
            ELSE 'Unknown'
        END as license_type,
        TRIM(assigned_to_user_id) as assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 1.0
            ELSE 0.0
        END as data_quality_score,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status
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
    data_quality_score,
    record_status
FROM transformed_licenses
