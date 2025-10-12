-- Silver layer licenses table with data quality checks and transformations
-- Transforms bronze licenses data with validation and cleansing

{{ config(
    materialized='table'
) }}

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
    1.0 as data_quality_score,
    'active' as record_status
FROM {{ source('bronze', 'bz_licenses') }}
WHERE license_id IS NOT NULL
  AND start_date IS NOT NULL
