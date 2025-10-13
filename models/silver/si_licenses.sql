{{ config(materialized='table') }}

WITH bronze_licenses AS (
    SELECT * FROM {{ source('bronze', 'bz_licenses') }}
),

users_ref AS (
    SELECT user_id FROM {{ ref('si_users') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        bl.*,
        -- Quality score calculation
        CASE 
            WHEN bl.license_id IS NULL THEN 0
            WHEN bl.license_type IS NULL THEN 0.2
            WHEN bl.start_date IS NULL OR bl.end_date IS NULL THEN 0.3
            WHEN bl.end_date <= bl.start_date THEN 0.4
            WHEN bl.assigned_to_user_id IS NOT NULL AND u.user_id IS NULL THEN 0.5  -- User doesn't exist
            WHEN bl.license_type NOT IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 0.7
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN bl.license_id IS NULL OR bl.license_type IS NULL THEN 'error'
            WHEN bl.start_date IS NULL OR bl.end_date IS NULL THEN 'error'
            WHEN bl.end_date <= bl.start_date THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_licenses bl
    LEFT JOIN users_ref u ON bl.assigned_to_user_id = u.user_id
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
            ELSE TRIM(license_type)
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
        record_status
    FROM dq_checks
    WHERE record_status = 'active'
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
FROM cleaned_licenses
