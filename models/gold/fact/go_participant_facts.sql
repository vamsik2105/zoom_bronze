{{ config(
    materialized='table',
    cluster_by=['join_time', 'meeting_id']
) }}

WITH participant_base AS (
    SELECT 
        p.participant_id,
        p.meeting_id,
        p.user_id,
        p.join_time,
        p.leave_time,
        p.load_date,
        p.source_system,
        p.data_quality_score
    FROM {{ source('silver', 'si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
),

meeting_hosts AS (
    SELECT 
        m.meeting_id,
        m.host_id
    FROM {{ source('silver', 'si_meetings') }} m
    WHERE m.record_status = 'ACTIVE'
),

feature_usage_by_participant AS (
    SELECT 
        f.meeting_id,
        p.participant_id,
        SUM(CASE WHEN f.feature_name = 'Screen Sharing' THEN f.usage_count ELSE 0 END) as screen_share_duration,
        SUM(CASE WHEN f.feature_name = 'Chat' THEN f.usage_count ELSE 0 END) as chat_messages_sent,
        COUNT(*) as interaction_count,
        MAX(CASE WHEN f.feature_name LIKE '%Audio%' THEN 'Computer Audio' ELSE 'Phone' END) as audio_connection_type,
        MAX(CASE WHEN f.feature_name = 'Video' THEN TRUE ELSE FALSE END) as video_enabled
    FROM {{ source('silver', 'si_feature_usage') }} f
    JOIN participant_base p ON f.meeting_id = p.meeting_id
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.meeting_id, p.participant_id
)

SELECT 
    CONCAT('PF_', pb.participant_id, '_', pb.meeting_id) as participant_fact_id,
    COALESCE(pb.meeting_id, 'UNKNOWN') as meeting_id,
    pb.participant_id,
    COALESCE(pb.user_id, 'GUEST_USER') as user_id,
    CONVERT_TIMEZONE('UTC', pb.join_time) as join_time,
    CONVERT_TIMEZONE('UTC', pb.leave_time) as leave_time,
    DATEDIFF('minute', pb.join_time, pb.leave_time) as attendance_duration,
    CASE 
        WHEN pb.user_id = mh.host_id THEN 'Host' 
        ELSE 'Participant' 
    END as participant_role,
    COALESCE(fu.audio_connection_type, 'Computer Audio') as audio_connection_type,
    COALESCE(fu.video_enabled, FALSE) as video_enabled,
    COALESCE(fu.screen_share_duration, 0) as screen_share_duration,
    COALESCE(fu.chat_messages_sent, 0) as chat_messages_sent,
    COALESCE(fu.interaction_count, 0) as interaction_count,
    ROUND(pb.data_quality_score, 2) as connection_quality_rating,
    'Desktop' as device_type,
    'Unknown' as geographic_location,
    pb.load_date,
    CURRENT_DATE() as update_date,
    pb.source_system
FROM participant_base pb
LEFT JOIN meeting_hosts mh ON pb.meeting_id = mh.meeting_id
LEFT JOIN feature_usage_by_participant fu ON pb.meeting_id = fu.meeting_id AND pb.participant_id = fu.participant_id
