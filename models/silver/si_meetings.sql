{{ config(
    materialized='incremental',
    unique_key='meeting_id',
    on_schema_change='fail',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_meetings']) }}', 'si_meetings_transformation', CURRENT_TIMESTAMP(), 'STARTED', 'Bronze', 'Silver', 'ETL', CURRENT_DATE(), CURRENT_DATE() WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_meetings']) }}' AND '{{ this.name }}' != 'si_process_audit'"
) }}

-- Silver Meetings Transformation with Data Quality Checks
WITH bronze_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY meeting_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     CASE WHEN meeting_topic IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN start_time IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN end_time IS NOT NULL THEN 1 ELSE 0 END DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_meetings') }}
    WHERE meeting_id IS NOT NULL
),

deduped_meetings AS (
    SELECT *
    FROM bronze_meetings
    WHERE row_rank = 1
),

data_quality_checks AS (
    SELECT 
        meeting_id,
        host_id,
        TRIM(meeting_topic) AS meeting_topic_clean,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Data Quality Score Calculation
        (
            CASE WHEN meeting_id IS NOT NULL THEN 0.2 ELSE 0 END +
            CASE WHEN host_id IS NOT NULL THEN 0.2 ELSE 0 END +
            CASE WHEN start_time IS NOT NULL THEN 0.2 ELSE 0 END +
            CASE WHEN end_time IS NOT NULL THEN 0.2 ELSE 0 END +
            CASE WHEN duration_minutes > 0 AND duration_minutes <= 1440 THEN 0.2 ELSE 0 END
        ) AS data_quality_score,
        -- Record Status
        CASE 
            WHEN meeting_id IS NULL THEN 'ERROR'
            WHEN host_id IS NULL THEN 'ERROR'
            WHEN start_time IS NULL OR end_time IS NULL THEN 'ERROR'
            WHEN end_time <= start_time THEN 'ERROR'
            WHEN duration_minutes <= 0 OR duration_minutes > 1440 THEN 'ERROR'
            ELSE 'ACTIVE'
        END AS record_status
    FROM deduped_meetings
),

final_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic_clean AS meeting_topic,
        start_time,
        end_time,
        duration_minutes,
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
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM final_meetings

{% if is_incremental() %}
    WHERE update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
