-- =====================================================
-- SILVER FEATURE USAGE MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

WITH bronze_feature_usage AS (
    SELECT *
    FROM {{ source('bronze', 'bz_feature_usage') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN usage_id IS NULL THEN 0 ELSE 1 END as usage_id_check,
        CASE WHEN meeting_id IS NULL THEN 0 ELSE 1 END as meeting_id_check,
        CASE WHEN feature_name IS NULL THEN 0 ELSE 1 END as feature_name_check,
        CASE WHEN usage_count IS NULL THEN 0 ELSE 1 END as usage_count_check,
        CASE WHEN usage_date IS NULL THEN 0 ELSE 1 END as usage_date_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Domain checks
        CASE WHEN feature_name IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 1 ELSE 0 END as feature_domain_check,
        CASE WHEN usage_count >= 0 THEN 1 ELSE 0 END as usage_count_check_range
    FROM bronze_feature_usage
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (usage_id_check + meeting_id_check + feature_name_check + usage_count_check + 
             usage_date_check + source_system_check + feature_domain_check + usage_count_check_range) / 8.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN usage_id IS NULL OR meeting_id IS NULL OR feature_name IS NULL OR usage_count IS NULL OR usage_date IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 'ERROR'
            WHEN usage_count < 0 THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_feature_usage AS (
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
    FROM quality_scored
    WHERE record_status = 'ACTIVE'
)

SELECT * FROM final_feature_usage
