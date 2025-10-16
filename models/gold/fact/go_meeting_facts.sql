{{ config(
    materialized='table',
    cluster_by=['load_date', 'meeting_id']
) }}

-- Meeting Facts transformation from Silver to Gold
WITH meeting_base AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        data_quality_score,
        load_date,
        source_system
    FROM {{ ref('si_meetings') }}
    WHERE record_status = 'ACTIVE'
),

participant_metrics AS (
    SELECT 
        p.meeting_id,
        COUNT(DISTINCT p.participant_id) as participant_count,
        SUM(DATEDIFF('minute', p.join_time, p.leave_time)) as total_attendance_minutes
    FROM {{ ref('si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
    GROUP BY p.meeting_id
),

feature_metrics AS (
    SELECT 
        f.meeting_id,
        SUM(CASE WHEN f.feature_name = 'Screen Sharing' THEN f.usage_count ELSE 0 END) as screen_share_count,
        SUM(CASE WHEN f.feature_name = 'Chat' THEN f.usage_count ELSE 0 END) as chat_message_count,
        SUM(CASE WHEN f.feature_name = 'Breakout Rooms' THEN f.usage_count ELSE 0 END) as breakout_room_count,
        MAX(CASE WHEN f.feature_name = 'Recording' THEN 1 ELSE 0 END) as recording_enabled
    FROM {{ ref('si_feature_usage') }} f
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.meeting_id
)

SELECT 
    CONCAT('MF_', m.meeting_id, '_', CURRENT_TIMESTAMP()::STRING) as meeting_fact_id,
    COALESCE(m.meeting_id, 'UNKNOWN') as meeting_id,
    CASE WHEN m.host_id IS NOT NULL THEN m.host_id ELSE 'UNKNOWN_HOST' END as host_id,
    TRIM(COALESCE(m.meeting_topic, 'No Topic Specified')) as meeting_topic,
    CONVERT_TIMEZONE('UTC', m.start_time) as start_time,
    CONVERT_TIMEZONE('UTC', m.end_time) as end_time,
    CASE WHEN m.duration_minutes > 0 THEN m.duration_minutes 
         ELSE DATEDIFF('minute', m.start_time, m.end_time) END as duration_minutes,
    COALESCE(pm.participant_count, 0) as participant_count,
    COALESCE(pm.participant_count, 0) as max_concurrent_participants,
    COALESCE(pm.total_attendance_minutes, 0) as total_attendance_minutes,
    CASE WHEN pm.participant_count > 0 
         THEN pm.total_attendance_minutes / pm.participant_count 
         ELSE 0 END as average_attendance_duration,
    CASE WHEN m.duration_minutes < 15 THEN 'Quick Meeting'
         WHEN m.duration_minutes < 60 THEN 'Standard Meeting'
         ELSE 'Extended Meeting' END as meeting_type,
    CASE WHEN m.end_time IS NOT NULL THEN 'Completed'
         WHEN m.start_time <= CURRENT_TIMESTAMP() THEN 'In Progress'
         ELSE 'Scheduled' END as meeting_status,
    CASE WHEN fm.recording_enabled = 1 THEN TRUE ELSE FALSE END as recording_enabled,
    COALESCE(fm.screen_share_count, 0) as screen_share_count,
    COALESCE(fm.chat_message_count, 0) as chat_message_count,
    COALESCE(fm.breakout_room_count, 0) as breakout_room_count,
    ROUND(m.data_quality_score, 2) as quality_score_avg,
    ROUND((COALESCE(fm.chat_message_count, 0) * 0.3 + 
           COALESCE(fm.screen_share_count, 0) * 0.4 + 
           COALESCE(pm.participant_count, 0) * 0.3) / 10, 2) as engagement_score,
    m.load_date,
    CURRENT_DATE() as update_date,
    m.source_system
FROM meeting_base m
LEFT JOIN participant_metrics pm ON m.meeting_id = pm.meeting_id
LEFT JOIN feature_metrics fm ON m.meeting_id = fm.meeting_id
