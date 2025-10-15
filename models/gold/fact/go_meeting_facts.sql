{{ config(
    materialized='table',
    cluster_by=['load_date', 'meeting_id']
) }}

WITH silver_meetings AS (
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
    FROM SILVER.si_meetings
    WHERE record_status = 'ACTIVE'
),

silver_participants AS (
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
    FROM SILVER.si_participants
    WHERE record_status = 'ACTIVE'
),

silver_feature_usage AS (
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
    FROM SILVER.si_feature_usage
    WHERE record_status = 'ACTIVE'
),

participant_metrics AS (
    SELECT 
        meeting_id,
        COUNT(DISTINCT participant_id) as participant_count,
        SUM(DATEDIFF('minute', join_time, COALESCE(leave_time, CURRENT_TIMESTAMP()))) as total_attendance_minutes
    FROM silver_participants
    GROUP BY meeting_id
),

feature_metrics AS (
    SELECT 
        meeting_id,
        SUM(CASE WHEN feature_name = 'Recording' THEN 1 ELSE 0 END) > 0 as recording_enabled,
        SUM(CASE WHEN feature_name = 'Screen Sharing' THEN usage_count ELSE 0 END) as screen_share_count,
        SUM(CASE WHEN feature_name = 'Chat' THEN usage_count ELSE 0 END) as chat_message_count,
        SUM(CASE WHEN feature_name = 'Breakout Rooms' THEN usage_count ELSE 0 END) as breakout_room_count
    FROM silver_feature_usage
    GROUP BY meeting_id
)

SELECT 
    CONCAT('MF_', sm.meeting_id, '_', CURRENT_TIMESTAMP()::STRING) as meeting_fact_id,
    COALESCE(sm.meeting_id, 'UNKNOWN') as meeting_id,
    CASE WHEN sm.host_id IS NOT NULL THEN sm.host_id ELSE 'UNKNOWN_HOST' END as host_id,
    TRIM(COALESCE(sm.meeting_topic, 'No Topic Specified')) as meeting_topic,
    sm.start_time as start_time,
    sm.end_time as end_time,
    CASE WHEN sm.duration_minutes > 0 THEN sm.duration_minutes 
         ELSE DATEDIFF('minute', sm.start_time, sm.end_time) END as duration_minutes,
    COALESCE(pm.participant_count, 0) as participant_count,
    COALESCE(pm.participant_count, 0) as max_concurrent_participants,
    COALESCE(pm.total_attendance_minutes, 0) as total_attendance_minutes,
    CASE WHEN pm.participant_count > 0 
         THEN pm.total_attendance_minutes / pm.participant_count 
         ELSE 0 END as average_attendance_duration,
    CASE WHEN sm.duration_minutes < 15 THEN 'Quick Meeting'
         WHEN sm.duration_minutes < 60 THEN 'Standard Meeting'
         ELSE 'Extended Meeting' END as meeting_type,
    CASE WHEN sm.end_time IS NOT NULL THEN 'Completed'
         WHEN sm.start_time <= CURRENT_TIMESTAMP() THEN 'In Progress'
         ELSE 'Scheduled' END as meeting_status,
    COALESCE(fm.recording_enabled, FALSE) as recording_enabled,
    COALESCE(fm.screen_share_count, 0) as screen_share_count,
    COALESCE(fm.chat_message_count, 0) as chat_message_count,
    COALESCE(fm.breakout_room_count, 0) as breakout_room_count,
    ROUND(sm.data_quality_score, 2) as quality_score_avg,
    ROUND((COALESCE(fm.chat_message_count, 0) * 0.3 + 
           COALESCE(fm.screen_share_count, 0) * 0.4 + 
           COALESCE(pm.participant_count, 0) * 0.3) / 10, 2) as engagement_score,
    sm.load_date,
    CURRENT_DATE() as update_date,
    sm.source_system
FROM silver_meetings sm
LEFT JOIN participant_metrics pm ON sm.meeting_id = pm.meeting_id
LEFT JOIN feature_metrics fm ON sm.meeting_id = fm.meeting_id
