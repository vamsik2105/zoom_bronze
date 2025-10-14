{{ config(
    materialized='table',
    unique_key='license_id'
) }}

-- Silver Licenses Table Transformation
WITH bronze_licenses AS (
    SELECT *
    FROM {{ source('bronze', 'bz_licenses') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Quality Score Calculation
        CASE 
            WHEN license_id IS NULL THEN 0
            WHEN start_date IS NULL OR end_date IS NULL THEN 0.3
            WHEN end_date <= start_date THEN 0.4
            WHEN license_type NOT IN ('Pro','Business','Enterprise','Education') THEN 0.6
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN license_id IS NULL THEN 'error'
            WHEN start_date IS NULL OR end_date IS NULL THEN 'error'
            WHEN end_date <= start_date THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_licenses
),

-- Clean and Transform Data
transformed_licenses AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(TRIM(license_type)) IN ('PRO','BUSINESS','ENTERPRISE','EDUCATION')
            THEN UPPER(TRIM(license_type))
            ELSE 'UNKNOWN'
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
    FROM data_quality_checks
    WHERE record_status = 'active'
)

SELECT * FROM transformed_licenses
