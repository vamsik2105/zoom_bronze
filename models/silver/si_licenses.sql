{{
    config(
        materialized='incremental',
        unique_key='license_id',
        on_schema_change='fail'
    )
}}

-- Silver Licenses Transformation with Data Quality Checks
WITH source_data AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY license_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     (CASE WHEN license_type IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN assigned_to_user_id IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN start_date IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN end_date IS NOT NULL THEN 1 ELSE 0 END) DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_licenses') }}
    WHERE license_id IS NOT NULL
    
    {% if is_incremental() %}
        AND update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
    {% endif %}
),

data_quality_checks AS (
    SELECT 
        *,
        -- License type validation
        CASE 
            WHEN UPPER(TRIM(license_type)) IN ('PRO', 'BUSINESS', 'ENTERPRISE', 'EDUCATION') THEN 1
            ELSE 0
        END AS license_type_valid,
        
        -- Date validation
        CASE 
            WHEN start_date IS NOT NULL AND end_date IS NOT NULL AND end_date > start_date THEN 1
            ELSE 0
        END AS date_valid,
        
        -- Completeness check
        CASE 
            WHEN license_id IS NOT NULL AND license_type IS NOT NULL AND start_date IS NOT NULL AND end_date IS NOT NULL THEN 1
            ELSE 0
        END AS completeness_check
    FROM source_data
    WHERE row_rank = 1
),

final_data AS (
    SELECT 
        license_id,
        CASE 
            WHEN UPPER(TRIM(license_type)) IN ('PRO', 'BUSINESS', 'ENTERPRISE', 'EDUCATION') 
                 THEN UPPER(TRIM(license_type))
            ELSE 'PRO'
        END AS license_type,
        assigned_to_user_id,  -- Can be nullable as per mapping
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        ROUND((license_type_valid + date_valid + completeness_check) / 3.0, 2) AS data_quality_score,
        CASE 
            WHEN license_type_valid = 1 AND date_valid = 1 AND completeness_check = 1 THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM data_quality_checks
)

SELECT * FROM final_data
WHERE record_status = 'active'  -- Only include valid records in Silver layer
