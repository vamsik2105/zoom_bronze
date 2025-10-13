{{ config(materialized='table') }}

-- Silver Licenses Table
WITH bronze_licenses AS (
    SELECT *
    FROM {{ source('bronze', 'bz_licenses') }}
),

valid_users AS (
    SELECT DISTINCT user_id FROM {{ ref('si_users') }}
),

data_quality_checks AS (
    SELECT 
        bl.*,
        
        -- Completeness checks
        CASE WHEN license_id IS NULL THEN 1 ELSE 0 END as missing_license_id,
        CASE WHEN start_date IS NULL THEN 1 ELSE 0 END as missing_start_date,
        CASE WHEN end_date IS NULL THEN 1 ELSE 0 END as missing_end_date,
        
        -- Domain validation
        CASE WHEN license_type IS NOT NULL AND license_type NOT IN ('Pro','Business','Enterprise','Education') 
             THEN 1 ELSE 0 END as invalid_license_type,
        
        -- Logical consistency
        CASE WHEN start_date IS NOT NULL AND end_date IS NOT NULL AND end_date <= start_date 
             THEN 1 ELSE 0 END as invalid_date_range,
        
        -- Referential integrity
        CASE WHEN assigned_to_user_id IS NOT NULL AND vu.user_id IS NULL THEN 1 ELSE 0 END as invalid_user_ref,
        
        -- Calculate data quality score
        CASE 
            WHEN license_id IS NULL OR start_date IS NULL OR end_date IS NULL THEN 0.0
            WHEN end_date <= start_date THEN 0.2
            WHEN license_type NOT IN ('Pro','Business','Enterprise','Education') THEN 0.4
            WHEN assigned_to_user_id IS NOT NULL AND vu.user_id IS NULL THEN 0.6
            ELSE 1.0
        END as data_quality_score
    FROM bronze_licenses bl
    LEFT JOIN valid_users vu ON bl.assigned_to_user_id = vu.user_id
)

SELECT 
    license_id,
    CASE 
        WHEN license_type IN ('Pro','Business','Enterprise','Education') 
        THEN license_type
        ELSE 'Pro'  -- Default to Pro for invalid values
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
        WHEN missing_license_id = 1 OR missing_start_date = 1 OR missing_end_date = 1 
             OR invalid_date_range = 1
        THEN 'error'
        ELSE 'active'
    END as record_status
FROM data_quality_checks
WHERE CASE 
        WHEN missing_license_id = 1 OR missing_start_date = 1 OR missing_end_date = 1 
             OR invalid_date_range = 1
        THEN 'error'
        ELSE 'active'
    END = 'active'
