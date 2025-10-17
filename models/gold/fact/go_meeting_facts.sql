{{ config(
    materialized='table',
    cluster_by=['start_time', 'host_id'],
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed) VALUES (CONCAT('EXEC_', CURRENT_TIMESTAMP()::STRING), 'go_meeting_facts', 'FACT_LOAD', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_USER()) WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}) WHERE pipeline_name = 'go_meeting_facts' AND status = 'STARTED' AND '{{ this.name }}' != 'go_process_audit'"
) }}

WITH meeting_base AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_date,
        source_system,
        data_quality_score
    FROM {{ ref('si_meetings') }}
    WHERE record_status = 'ACTIVE'
),

participant_metrics AS (
    SELECT 
        p.meeting_id,
        COUNT(DISTINCT p.participant_id) as participant_count,
        SUM(DATEDIFF('minute', p.join_time, p.leave_time)) as total_attendance_minutes,
        AVG(DATEDIFF('minute', p.join_time, p.leave_time)) as average_attendance_duration
    FROM {{ ref('si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
    GROUP BY p.meeting_id
),

feature_metrics AS (
    SELECT 
        f.meeting_id,
        SUM(CASE WHEN f.feature_name = 'Recording' THEN 1 ELSE 0 END) > 0 as recording_enabled,
        SUM(CASE WHEN f.feature_name = 'Screen Sharing' THEN f.usage_count ELSE 0 END) as screen_share_count,
        SUM(CASE WHEN f.feature_name = 'Chat' THEN f.usage_count ELSE 0 END) as chat_message_count,
        SUM(CASE WHEN f.feature_name = 'Breakout Rooms' THEN f.usage_count ELSE 0 END) as breakout_room_count
    FROM {{ ref('si_feature_usage') }} f
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.meeting_id
)

SELECT 
    CONCAT('MF_', mb.meeting_id, '_', CURRENT_TIMESTAMP()::STRING) as meeting_fact_id,
    COALESCE(mb.meeting_id, 'UNKNOWN') as meeting_id,
    CASE WHEN mb.host_id IS NOT NULL THEN mb.host_id ELSE 'UNKNOWN_HOST' END as host_id,
    TRIM(COALESCE(mb.meeting_topic, 'No Topic Specified')) as meeting_topic,
    CONVERT_TIMEZONE('UTC', mb.start_time) as start_time,
    CONVERT_TIMEZONE('UTC', mb.end_time) as end_time,
    CASE 
        WHEN mb.duration_minutes > 0 THEN mb.duration_minutes 
        ELSE DATEDIFF('minute', mb.start_time, mb.end_time) 
    END as duration_minutes,
    COALESCE(pm.participant_count, 0) as participant_count,
    COALESCE(pm.participant_count, 0) as max_concurrent_participants,
    COALESCE(pm.total_attendance_minutes, 0) as total_attendance_minutes,
    COALESCE(pm.average_attendance_duration, 0) as average_attendance_duration,
    CASE 
        WHEN mb.duration_minutes < 15 THEN 'Quick Meeting'
        WHEN mb.duration_minutes < 60 THEN 'Standard Meeting'
        ELSE 'Extended Meeting'
    END as meeting_type,
    CASE 
        WHEN mb.end_time IS NOT NULL THEN 'Completed'
        WHEN mb.start_time <= CURRENT_TIMESTAMP() THEN 'In Progress'
        ELSE 'Scheduled'
    END as meeting_status,
    COALESCE(fm.recording_enabled, FALSE) as recording_enabled,
    COALESCE(fm.screen_share_count, 0) as screen_share_count,
    COALESCE(fm.chat_message_count, 0) as chat_message_count,
    COALESCE(fm.breakout_room_count, 0) as breakout_room_count,
    ROUND(mb.data_quality_score, 2) as quality_score_avg,
    ROUND((COALESCE(fm.chat_message_count, 0) * 0.3 + COALESCE(fm.screen_share_count, 0) * 0.4 + COALESCE(pm.participant_count, 0) * 0.3) / 10, 2) as engagement_score,
    mb.load_date,
    CURRENT_DATE() as update_date,
    mb.source_system
FROM meeting_base mb
LEFT JOIN participant_metrics pm ON mb.meeting_id = pm.meeting_id
LEFT JOIN feature_metrics fm ON mb.meeting_id = fm.meeting_id
