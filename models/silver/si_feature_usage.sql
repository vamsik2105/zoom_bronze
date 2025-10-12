-- Silver Feature Usage Table - Cleaned and validated feature usage data

{{ config(
    materialized='table',
    unique_key='usage_id'
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

validated_feature_usage AS (
    SELECT 
        *,
        CASE 
            WHEN usage_id IS NULL THEN 'NULL_USAGE_ID'
            WHEN meeting_id IS NULL THEN 'NULL_MEETING_ID'
            WHEN feature_name IS NULL THEN 'NULL_FEATURE_NAME'
            WHEN feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 'INVALID_FEATURE_NAME'
            WHEN usage_count IS NULL OR usage_count < 0 THEN 'INVALID_USAGE_COUNT'
            WHEN usage_date IS NULL THEN 'NULL_USAGE_DATE'
            WHEN source_system IS NULL THEN 'NULL_SOURCE_SYSTEM'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_feature_usage
),

transformed_feature_usage AS (
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
        END AS feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        {{ calculate_data_quality_score('si_feature_usage', 'usage_id') }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status,
        validation_status
    FROM validated_feature_usage
)

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
    data_quality_score,
    record_status
FROM transformed_feature_usage
WHERE validation_status = 'VALID'

UNION ALL

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
    0.0 AS data_quality_score,
    'error' AS record_status
FROM transformed_feature_usage
WHERE validation_status != 'VALID'
