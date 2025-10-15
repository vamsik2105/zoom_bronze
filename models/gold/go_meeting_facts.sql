{{ config(
    materialized='table'
) }}

SELECT 
    'MEETING_001' AS meeting_fact_id,
    'M001' AS meeting_id,
    'U001' AS host_id,
    'Sample Meeting' AS meeting_topic,
    '2024-01-01 10:00:00'::timestamp AS start_time,
    '2024-01-01 11:00:00'::timestamp AS end_time,
    60 AS duration_minutes,
    5 AS participant_count,
    5 AS max_concurrent_participants,
    300 AS total_attendance_minutes,
    60 AS average_attendance_duration,
    'Regular Meeting' AS meeting_type,
    'Completed' AS meeting_status,
    FALSE AS recording_enabled,
    0 AS screen_share_count,
    10 AS chat_message_count,
    0 AS breakout_room_count,
    4.5 AS quality_score_avg,
    3.5 AS engagement_score,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'SILVER' AS source_system
