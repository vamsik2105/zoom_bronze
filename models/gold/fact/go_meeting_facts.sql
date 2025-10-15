{{ config(
    materialized='table'
) }}

WITH silver_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        source_system,
        load_date,
        data_quality_score
    FROM SILVER.si_meetings
    WHERE record_status = 'ACTIVE'
),

silver_participants AS (
    SELECT 
        meeting_id,
        COUNT(DISTINCT participant_id) as participant_count,
        SUM(DATEDIFF('minute', join_time, COALESCE(leave_time, CURRENT_TIMESTAMP()))) as total_attendance_minutes
    FROM SILVER.si_participants
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
),

silver_features AS (
    SELECT 
        meeting_id,
        SUM(CASE WHEN feature_name = 'Screen Sharing' THEN usage_count ELSE 0 END) as screen_share_count,
        SUM(CASE WHEN feature_name = 'Chat' THEN usage_count ELSE 0 END) as chat_message_count
    FROM SILVER.si_feature_usage
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
)

SELECT 
    CONCAT('MF_', sm.meeting_id) as meeting_fact_id,
    sm.meeting_id,
    COALESCE(sm.host_id, 'UNKNOWN_HOST') as host_id,
    COALESCE(sm.meeting_topic, 'No Topic Specified') as meeting_topic,
    sm.start_time,
    sm.end_time,
    COALESCE(sm.duration_minutes, 0) as duration_minutes,
    COALESCE(sp.participant_count, 0) as participant_count,
    COALESCE(sp.participant_count, 0) as max_concurrent_participants,
    COALESCE(sp.total_attendance_minutes, 0) as total_attendance_minutes,
    CASE WHEN sp.participant_count > 0 
         THEN sp.total_attendance_minutes / sp.participant_count 
         ELSE 0 END as average_attendance_duration,
    CASE WHEN sm.duration_minutes < 15 THEN 'Quick Meeting'
         WHEN sm.duration_minutes < 60 THEN 'Standard Meeting'
         ELSE 'Extended Meeting' END as meeting_type,
    CASE WHEN sm.end_time IS NOT NULL THEN 'Completed'
         ELSE 'In Progress' END as meeting_status,
    FALSE as recording_enabled,
    COALESCE(sf.screen_share_count, 0) as screen_share_count,
    COALESCE(sf.chat_message_count, 0) as chat_message_count,
    0 as breakout_room_count,
    ROUND(sm.data_quality_score, 2) as quality_score_avg,
    ROUND((COALESCE(sf.chat_message_count, 0) * 0.3 + 
           COALESCE(sf.screen_share_count, 0) * 0.4 + 
           COALESCE(sp.participant_count, 0) * 0.3) / 10, 2) as engagement_score,
    sm.load_date,
    CURRENT_DATE() as update_date,
    sm.source_system
FROM silver_meetings sm
LEFT JOIN silver_participants sp ON sm.meeting_id = sp.meeting_id
LEFT JOIN silver_features sf ON sm.meeting_id = sf.meeting_id
