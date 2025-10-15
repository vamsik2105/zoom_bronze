{{ config(
    materialized='table'
) }}

SELECT 
    'MF_001' as meeting_fact_id,
    'MEETING_001' as meeting_id,
    'HOST_001' as host_id,
    'Sample Meeting' as meeting_topic,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    60 as duration_minutes,
    5 as participant_count,
    5 as max_concurrent_participants,
    300 as total_attendance_minutes,
    60 as average_attendance_duration,
    'Standard Meeting' as meeting_type,
    'Completed' as meeting_status,
    TRUE as recording_enabled,
    2 as screen_share_count,
    15 as chat_message_count,
    0 as breakout_room_count,
    8.5 as quality_score_avg,
    7.2 as engagement_score,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_ANALYTICS' as source_system
