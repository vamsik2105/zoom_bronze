{{ config(
    materialized='table',
    unique_key='usage_id'
) }}

-- Silver Feature Usage Table Transformation
WITH bronze_feature_usage AS (
    SELECT *
    FROM {{ source('bronze', 'bz_feature_usage') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Quality Score Calculation
        CASE 
            WHEN usage_id IS NULL THEN 0
            WHEN meeting_id IS NULL THEN 0.2
            WHEN feature_name IS NULL THEN 0.3
            WHEN usage_count IS NULL OR usage_count < 0 THEN 0.4
            WHEN feature_name NOT IN ('Screen Sharing','Chat','Recording','Whiteboard','Virtual Background') THEN 0.6
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN usage_id IS NULL OR meeting_id IS NULL OR feature_name IS NULL THEN 'error'
            WHEN usage_count IS NULL OR usage_count < 0 THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_feature_usage
),

-- Clean and Transform Data
transformed_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN UPPER(TRIM(feature_name)) IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND')
            THEN UPPER(TRIM(feature_name))
            ELSE 'OTHER'
        END AS feature_name,
        usage_count,
        usage_date,
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

SELECT * FROM transformed_feature_usage
