{{ config(
    materialized='incremental',
    unique_key='usage_id',
    on_schema_change='fail',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_feature_usage']) }}', 'si_feature_usage_transformation', CURRENT_TIMESTAMP(), 'STARTED', 'Bronze', 'Silver', 'ETL', CURRENT_DATE(), CURRENT_DATE() WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_feature_usage']) }}' AND '{{ this.name }}' != 'si_process_audit'"
) }}

-- Silver Feature Usage Transformation with Data Quality Checks
WITH bronze_feature_usage AS (
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
                     CASE WHEN feature_name IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN usage_count IS NOT NULL THEN 1 ELSE 0 END DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_feature_usage') }}
    WHERE usage_id IS NOT NULL
),

deduped_feature_usage AS (
    SELECT *
    FROM bronze_feature_usage
    WHERE row_rank = 1
),

data_quality_checks AS (
    SELECT 
        usage_id,
        meeting_id,
        CASE 
            WHEN UPPER(TRIM(feature_name)) IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND') 
            THEN UPPER(TRIM(feature_name))
            ELSE 'OTHER'
        END AS feature_name_clean,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Data Quality Score Calculation
        (
            CASE WHEN usage_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN meeting_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN UPPER(TRIM(feature_name)) IN ('SCREEN SHARING', 'CHAT', 'RECORDING', 'WHITEBOARD', 'VIRTUAL BACKGROUND') THEN 0.25 ELSE 0 END +
            CASE WHEN usage_count >= 0 THEN 0.25 ELSE 0 END
        ) AS data_quality_score,
        -- Record Status
        CASE 
            WHEN usage_id IS NULL THEN 'ERROR'
            WHEN meeting_id IS NULL THEN 'ERROR'
            WHEN feature_name IS NULL OR TRIM(feature_name) = '' THEN 'ERROR'
            WHEN usage_count < 0 THEN 'ERROR'
            ELSE 'ACTIVE'
        END AS record_status
    FROM deduped_feature_usage
),

final_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name_clean AS feature_name,
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
    WHERE record_status = 'ACTIVE'  -- Only pass clean records to Silver
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
FROM final_feature_usage

{% if is_incremental() %}
    WHERE update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
