{{ config(
    materialized='table'
) }}

SELECT 
    CONCAT('MF_', meeting_id) as meeting_fact_id,
    meeting_id,
    COALESCE(host_id, 'UNKNOWN_HOST') as host_id,
    COALESCE(meeting_topic, 'No Topic Specified') as meeting_topic,
    start_time,
    end_time,
    COALESCE(duration_minutes, 0) as duration_minutes,
    0 as participant_count,
    0 as max_concurrent_participants,
    0 as total_attendance_minutes,
    0 as average_attendance_duration,
    CASE WHEN duration_minutes < 15 THEN 'Quick Meeting'
         WHEN duration_minutes < 60 THEN 'Standard Meeting'
         ELSE 'Extended Meeting' END as meeting_type,
    CASE WHEN end_time IS NOT NULL THEN 'Completed'
         ELSE 'In Progress' END as meeting_status,
    FALSE as recording_enabled,
    0 as screen_share_count,
    0 as chat_message_count,
    0 as breakout_room_count,
    ROUND(COALESCE(data_quality_score, 0), 2) as quality_score_avg,
    0 as engagement_score,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM SILVER.si_meetings
WHERE record_status = 'ACTIVE'
