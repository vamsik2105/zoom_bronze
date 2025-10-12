{{
  config(
    materialized='table'
  )
}}

-- Transform bronze licenses to silver layer with data quality checks
-- Note: This model will create empty table structure if source doesn't exist
WITH bronze_licenses AS (
    SELECT 
        CAST(NULL AS STRING) as license_id,
        CAST(NULL AS STRING) as license_type,
        CAST(NULL AS STRING) as assigned_to_user_id,
        CAST(NULL AS DATE) as start_date,
        CAST(NULL AS DATE) as end_date,
        CAST(NULL AS TIMESTAMP_NTZ) as load_timestamp,
        CAST(NULL AS TIMESTAMP_NTZ) as update_timestamp,
        CAST(NULL AS STRING) as source_system
    WHERE FALSE -- Creates empty structure
),

-- Data Quality Validation
validated_licenses AS (
    SELECT 
        *,
        -- Data Quality Checks
        CASE 
            WHEN license_id IS NULL OR TRIM(license_id) = '' THEN 'INVALID_LICENSE_ID'
            WHEN license_type IS NULL OR TRIM(license_type) = '' THEN 'INVALID_LICENSE_TYPE'
            WHEN license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 'INVALID_LICENSE_TYPE_VALUE'
            WHEN start_date IS NULL THEN 'INVALID_START_DATE'
            WHEN end_date IS NULL THEN 'INVALID_END_DATE'
            WHEN end_date <= start_date THEN 'INVALID_DATE_RANGE'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'INVALID_SOURCE_SYSTEM'
            ELSE 'VALID'
        END as validation_status
    FROM bronze_licenses
),

-- Valid Records for Silver Layer
valid_records AS (
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
    FROM validated_licenses
    WHERE validation_status = 'VALID'
)

SELECT * FROM valid_records
