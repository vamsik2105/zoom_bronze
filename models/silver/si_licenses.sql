-- Silver Licenses Table - Cleaned and validated license data

{{ config(
    materialized='table',
    unique_key='license_id'
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
            WHEN source_system IS NULL THEN 'NULL_SOURCE_SYSTEM'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_licenses
),

transformed_licenses AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(TRIM(license_type)) = 'PRO' THEN 'Pro'
            WHEN UPPER(TRIM(license_type)) = 'BUSINESS' THEN 'Business'
            WHEN UPPER(TRIM(license_type)) = 'ENTERPRISE' THEN 'Enterprise'
            WHEN UPPER(TRIM(license_type)) = 'EDUCATION' THEN 'Education'
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
        {{ calculate_data_quality_score('si_licenses', 'license_id') }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status,
        validation_status
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
WHERE validation_status = 'VALID'

UNION ALL

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
    0.0 AS data_quality_score,
    'error' AS record_status
FROM transformed_licenses
WHERE validation_status != 'VALID'
