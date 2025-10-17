{{ config(
    materialized='table',
    cluster_by=['start_time', 'host_id']
) }}

SELECT 
    CONCAT('MF_', meeting_id, '_', CURRENT_TIMESTAMP()::STRING) as meeting_fact_id,
    COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
    CASE WHEN host_id IS NOT NULL THEN host_id ELSE 'UNKNOWN_HOST' END as host_id,
    TRIM(COALESCE(meeting_topic, 'No Topic Specified')) as meeting_topic,
    CONVERT_TIMEZONE('UTC', start_time) as start_time,
    CONVERT_TIMEZONE('UTC', end_time) as end_time,
    CASE 
        WHEN duration_minutes > 0 THEN duration_minutes 
        ELSE DATEDIFF('minute', start_time, end_time) 
    END as duration_minutes,
    0 as participant_count,
    0 as max_concurrent_participants,
    0 as total_attendance_minutes,
    0 as average_attendance_duration,
    CASE 
        WHEN duration_minutes < 15 THEN 'Quick Meeting'
        WHEN duration_minutes < 60 THEN 'Standard Meeting'
        ELSE 'Extended Meeting'
    END as meeting_type,
    CASE 
        WHEN end_time IS NOT NULL THEN 'Completed'
        WHEN start_time <= CURRENT_TIMESTAMP() THEN 'In Progress'
        ELSE 'Scheduled'
    END as meeting_status,
    FALSE as recording_enabled,
    0 as screen_share_count,
    0 as chat_message_count,
    0 as breakout_room_count,
    ROUND(data_quality_score, 2) as quality_score_avg,
    0.0 as engagement_score,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM ZOOM.SILVER.si_meetings
WHERE record_status = 'ACTIVE'
