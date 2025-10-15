{{ config(
    materialized='incremental',
    unique_key='participant_id',
    on_schema_change='fail',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_participants']) }}', 'si_participants_transformation', CURRENT_TIMESTAMP(), 'STARTED', 'Bronze', 'Silver', 'ETL', CURRENT_DATE(), CURRENT_DATE() WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_participants']) }}' AND '{{ this.name }}' != 'si_process_audit'"
) }}

-- Silver Participants Transformation with Data Quality Checks
WITH bronze_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY participant_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     CASE WHEN join_time IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN leave_time IS NOT NULL THEN 1 ELSE 0 END DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_participants') }}
    WHERE participant_id IS NOT NULL
),

deduped_participants AS (
    SELECT *
    FROM bronze_participants
    WHERE row_rank = 1
),

data_quality_checks AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Data Quality Score Calculation
        (
            CASE WHEN participant_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN meeting_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN join_time IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN leave_time IS NOT NULL AND leave_time > join_time THEN 0.25 ELSE 0 END
        ) AS data_quality_score,
        -- Record Status
        CASE 
            WHEN participant_id IS NULL THEN 'ERROR'
            WHEN meeting_id IS NULL THEN 'ERROR'
            WHEN join_time IS NULL OR leave_time IS NULL THEN 'ERROR'
            WHEN leave_time <= join_time THEN 'ERROR'
            ELSE 'ACTIVE'
        END AS record_status
    FROM deduped_participants
),

final_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
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
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM final_participants

{% if is_incremental() %}
    WHERE update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
