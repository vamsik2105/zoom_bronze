-- Silver layer feature usage table with data quality checks and transformations
-- Transforms bronze feature usage data with validation and cleansing

{{ config(
    materialized='table'
) }}

WITH bronze_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('bronze', 'bz_feature_usage') }}
),

-- Data quality validation
validated_feature_usage AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN usage_id IS NULL THEN 1 ELSE 0 END as null_usage_id,
        CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as null_meeting_id,
        CASE WHEN feature_name IS NULL THEN 1 ELSE 0 END as null_feature_name,
        
        -- Domain validation
        CASE WHEN feature_name IS NOT NULL AND feature_name NOT IN ('Screen Sharing','Chat','Recording','Whiteboard','Virtual Background') 
             THEN 1 ELSE 0 END as invalid_feature_name,
        CASE WHEN usage_count IS NOT NULL AND usage_count < 0 
             THEN 1 ELSE 0 END as invalid_usage_count
    FROM bronze_feature_usage
),

-- Clean and transform data
cleaned_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN UPPER(TRIM(feature_name)) = 'SCREEN SHARING' THEN 'Screen Sharing'
            WHEN UPPER(TRIM(feature_name)) = 'CHAT' THEN 'Chat'
            WHEN UPPER(TRIM(feature_name)) = 'RECORDING' THEN 'Recording'
            WHEN UPPER(TRIM(feature_name)) = 'WHITEBOARD' THEN 'Whiteboard'
            WHEN UPPER(TRIM(feature_name)) = 'VIRTUAL BACKGROUND' THEN 'Virtual Background'
            ELSE feature_name
        END as feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        
        -- Data quality flags
        null_usage_id + null_meeting_id + null_feature_name + invalid_feature_name + invalid_usage_count as error_count,
        
        -- Record status
        CASE 
            WHEN null_usage_id = 1 OR null_meeting_id = 1 OR null_feature_name = 1 OR invalid_feature_name = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_feature_usage
),

-- Calculate data quality score
final_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        load_date,
        update_date,
        
        -- Data quality score calculation
        CASE 
            WHEN error_count = 0 THEN 1.0
            WHEN error_count = 1 THEN 0.8
            WHEN error_count = 2 THEN 0.6
            WHEN error_count = 3 THEN 0.4
            WHEN error_count = 4 THEN 0.2
            ELSE 0.0
        END as data_quality_score,
        
        record_status
    FROM cleaned_feature_usage
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_feature_usage
