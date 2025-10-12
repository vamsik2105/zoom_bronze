{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'si_licenses', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED'",
    post_hook="UPDATE {{ ref('si_audit_log') }} SET status = 'COMPLETED', processing_time = 10 WHERE source_table = 'si_licenses' AND status = 'STARTED'"
) }}

-- Transform bronze licenses data to silver layer with data quality checks
WITH bronze_licenses AS (
    SELECT *
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
        END AS validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN license_id IS NOT NULL 
                AND license_type IN ('Pro', 'Business', 'Enterprise', 'Education')
                AND start_date IS NOT NULL
                AND end_date IS NOT NULL
                AND end_date > start_date
            THEN 1.0
            WHEN license_id IS NOT NULL AND license_type IS NOT NULL
            THEN 0.75
            WHEN license_id IS NOT NULL
            THEN 0.5
            ELSE 0.0
        END AS data_quality_score
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_licenses
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_licenses
