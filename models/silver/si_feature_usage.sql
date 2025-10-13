{{ config(materialized='table') }}

WITH bronze_feature_usage AS (
    SELECT *
    FROM {{ source('bronze', 'bz_feature_usage') }}
),

-- Data Quality Checks
quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN usage_id IS NULL THEN 0 ELSE 1 END as usage_id_complete,
        CASE WHEN meeting_id IS NULL THEN 0 ELSE 1 END as meeting_id_complete,
        CASE WHEN feature_name IS NULL THEN 0 ELSE 1 END as feature_name_complete,
        
        -- Domain checks
        CASE WHEN feature_name IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 1 ELSE 0 END as feature_name_valid,
        CASE WHEN usage_count >= 0 THEN 1 ELSE 0 END as usage_count_valid
    FROM bronze_feature_usage
),

-- Calculate data quality score
scored_data AS (
    SELECT 
        *,
        ROUND(
            (usage_id_complete + meeting_id_complete + feature_name_complete + feature_name_valid + usage_count_valid) / 5.0, 2
        ) as data_quality_score,
        CASE 
            WHEN usage_id IS NULL OR meeting_id IS NULL OR feature_name IS NULL THEN 'error'
            WHEN usage_count < 0 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM quality_checks
),

-- Final transformation
final_data AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN feature_name IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN feature_name
            ELSE 'Other'
        END as feature_name,
        usage_count,
        usage_date,
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
