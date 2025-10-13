{{ config(materialized='table') }}

WITH bronze_licenses AS (
    SELECT *
    FROM {{ source('bronze', 'bz_licenses') }}
),

-- Data Quality Checks
quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN license_id IS NULL THEN 0 ELSE 1 END as license_id_complete,
        CASE WHEN start_date IS NULL THEN 0 ELSE 1 END as start_date_complete,
        CASE WHEN end_date IS NULL THEN 0 ELSE 1 END as end_date_complete,
        
        -- Domain checks
        CASE WHEN license_type IN ('Pro', 'Business', 'Enterprise', 'Education') THEN 1 ELSE 0 END as license_type_valid,
        CASE WHEN end_date > start_date THEN 1 ELSE 0 END as date_logic_valid
    FROM bronze_licenses
),

-- Calculate data quality score
scored_data AS (
    SELECT 
        *,
        ROUND(
            (license_id_complete + start_date_complete + end_date_complete + license_type_valid + date_logic_valid) / 5.0, 2
        ) as data_quality_score,
        CASE 
            WHEN license_id IS NULL OR start_date IS NULL OR end_date IS NULL THEN 'error'
            WHEN end_date <= start_date THEN 'error'
            ELSE 'active'
        END as record_status
    FROM quality_checks
),

-- Final transformation
final_data AS (
    SELECT 
        license_id,
        CASE 
            WHEN license_type IN ('Pro', 'Business', 'Enterprise', 'Education') THEN license_type
            ELSE 'Unknown'
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
        record_status
    FROM scored_data
    WHERE record_status = 'active'
)

SELECT * FROM final_data
