{{ config(materialized='table') }}

-- Silver Feature Usage Table
WITH bronze_feature_usage AS (
    SELECT *
    FROM {{ source('bronze', 'bz_feature_usage') }}
),

valid_meetings AS (
    SELECT DISTINCT meeting_id FROM {{ ref('si_meetings') }}
),

data_quality_checks AS (
    SELECT 
        bfu.*,
        
        -- Completeness checks
        CASE WHEN usage_id IS NULL THEN 1 ELSE 0 END as missing_usage_id,
        CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as missing_meeting_id,
        CASE WHEN feature_name IS NULL THEN 1 ELSE 0 END as missing_feature_name,
        
        -- Domain validation
        CASE WHEN feature_name IS NOT NULL AND feature_name NOT IN 
             ('Screen Sharing','Chat','Recording','Whiteboard','Virtual Background') 
             THEN 1 ELSE 0 END as invalid_feature_name,
        
        -- Range validation
        CASE WHEN usage_count IS NOT NULL AND usage_count < 0 THEN 1 ELSE 0 END as invalid_usage_count,
        
        -- Referential integrity
        CASE WHEN vm.meeting_id IS NULL THEN 1 ELSE 0 END as invalid_meeting_ref,
        
        -- Calculate data quality score
        CASE 
            WHEN usage_id IS NULL OR meeting_id IS NULL OR feature_name IS NULL THEN 0.0
            WHEN vm.meeting_id IS NULL THEN 0.2
            WHEN feature_name NOT IN ('Screen Sharing','Chat','Recording','Whiteboard','Virtual Background') THEN 0.4
            WHEN usage_count < 0 THEN 0.6
            ELSE 1.0
        END as data_quality_score
    FROM bronze_feature_usage bfu
    LEFT JOIN valid_meetings vm ON bfu.meeting_id = vm.meeting_id
)

SELECT 
    usage_id,
    meeting_id,
    CASE 
        WHEN feature_name IN ('Screen Sharing','Chat','Recording','Whiteboard','Virtual Background') 
        THEN feature_name
        ELSE 'Other'  -- Standardize invalid values
    END as feature_name,
    CASE WHEN usage_count >= 0 THEN usage_count ELSE 0 END as usage_count,
    usage_date,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    data_quality_score,
    CASE 
        WHEN missing_usage_id = 1 OR missing_meeting_id = 1 OR missing_feature_name = 1 
             OR invalid_meeting_ref = 1
        THEN 'error'
        ELSE 'active'
    END as record_status
FROM data_quality_checks
WHERE CASE 
        WHEN missing_usage_id = 1 OR missing_meeting_id = 1 OR missing_feature_name = 1 
             OR invalid_meeting_ref = 1
        THEN 'error'
        ELSE 'active'
    END = 'active'
