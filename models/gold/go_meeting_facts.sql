{{ config(
    materialized='table'
) }}

WITH meeting_base AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver_layer', 'si_meetings') }}
    WHERE record_status = 'ACTIVE'
      AND start_time IS NOT NULL
      AND end_time IS NOT NULL
)

SELECT 
    MD5(CAST(COALESCE(CAST(meeting_id AS VARCHAR), '_dbt_utils_surrogate_key_null_') AS VARCHAR)) AS meeting_fact_id,
    meeting_id,
    host_id,
    COALESCE(meeting_topic, 'Untitled Meeting') AS meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    0 AS participant_count,
    0 AS max_concurrent_participants,
    0 AS total_attendance_minutes,
    0 AS average_attendance_duration,
    'Regular Meeting' AS meeting_type,
    'Completed' AS meeting_status,
    FALSE AS recording_enabled,
    0 AS screen_share_count,
    0 AS chat_message_count,
    0 AS breakout_room_count,
    0.0 AS quality_score_avg,
    2.5 AS engagement_score,
    load_date,
    update_date,
    source_system
FROM meeting_base
