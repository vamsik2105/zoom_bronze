{{ config(
    materialized='table'
) }}

SELECT 
    meeting_id as meeting_fact_id,
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    0 as participant_count,
    0 as max_concurrent_participants,
    0 as total_attendance_minutes,
    0 as average_attendance_duration,
    'Standard Meeting' as meeting_type,
    'Completed' as meeting_status,
    FALSE as recording_enabled,
    0 as screen_share_count,
    0 as chat_message_count,
    0 as breakout_room_count,
    data_quality_score as quality_score_avg,
    0.0 as engagement_score,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM SILVER.si_meetings
WHERE record_status = 'ACTIVE'
