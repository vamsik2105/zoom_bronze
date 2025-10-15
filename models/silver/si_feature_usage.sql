{{
    config(
        materialized='incremental',
        unique_key='usage_id',
        on_schema_change='fail'
    )
}}

-- Silver Feature Usage Transformation with Data Quality Checks
WITH source_data AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY usage_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     (CASE WHEN meeting_id IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN feature_name IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN usage_count IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN usage_date IS NOT NULL THEN 1 ELSE 0 END) DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_feature_usage') }}
    WHERE usage_id IS NOT NULL
    
    {% if is_incremental() %}
        AND update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
    {% endif %}
),

data_quality_checks AS (
    SELECT 
        *,
        -- Feature name validation
        CASE 
            WHEN UPPER(TRIM(feature_name)) IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND') THEN 1
            ELSE 0
        END AS feature_valid,
        
        -- Usage count validation
        CASE 
            WHEN usage_count IS NOT NULL AND usage_count >= 0 THEN 1
            ELSE 0
        END AS count_valid,
        
        -- Meeting reference check
        CASE 
            WHEN meeting_id IS NOT NULL AND TRIM(meeting_id) != '' THEN 1
            ELSE 0
        END AS meeting_valid,
        
        -- Completeness check
        CASE 
            WHEN usage_id IS NOT NULL AND meeting_id IS NOT NULL AND feature_name IS NOT NULL AND usage_date IS NOT NULL THEN 1
            ELSE 0
        END AS completeness_check
    FROM source_data
    WHERE row_rank = 1
),

final_data AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN UPPER(TRIM(feature_name)) IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND') 
                 THEN UPPER(TRIM(feature_name))
            ELSE 'UNKNOWN'
        END AS feature_name,
        COALESCE(usage_count, 0) AS usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        ROUND((feature_valid + count_valid + meeting_valid + completeness_check) / 4.0, 2) AS data_quality_score,
        CASE 
            WHEN feature_valid = 1 AND count_valid = 1 AND meeting_valid = 1 AND completeness_check = 1 THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM data_quality_checks
)

SELECT * FROM final_data
WHERE record_status = 'active'  -- Only include valid records in Silver layer
