{{ config(materialized='table') }}

WITH bronze_feature_usage AS (
    SELECT * FROM {{ source('bronze', 'bz_feature_usage') }}
),

meetings_ref AS (
    SELECT meeting_id FROM {{ ref('si_meetings') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        bfu.*,
        -- Quality score calculation
        CASE 
            WHEN bfu.usage_id IS NULL THEN 0
            WHEN bfu.meeting_id IS NULL THEN 0.2
            WHEN bfu.feature_name IS NULL THEN 0.3
            WHEN bfu.usage_count IS NULL OR bfu.usage_count < 0 THEN 0.4
            WHEN m.meeting_id IS NULL THEN 0.5  -- Meeting doesn't exist
            WHEN bfu.feature_name NOT IN ('Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background') THEN 0.7
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN bfu.usage_id IS NULL OR bfu.meeting_id IS NULL OR bfu.feature_name IS NULL THEN 'error'
            WHEN bfu.usage_count IS NULL OR bfu.usage_count < 0 THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_feature_usage bfu
    LEFT JOIN meetings_ref m ON bfu.meeting_id = m.meeting_id
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
            ELSE TRIM(feature_name)
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
    FROM dq_checks
    WHERE record_status = 'active'
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
FROM cleaned_feature_usage
