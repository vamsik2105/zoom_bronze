{{ config(
    materialized='table'
) }}

WITH participant_base AS (
    SELECT 
        p.participant_id,
        p.meeting_id,
        p.user_id,
        p.join_time,
        p.leave_time,
        p.data_quality_score,
        p.load_date,
        p.source_system,
        m.host_id
    FROM {{ source('silver', 'si_participants') }} p
    LEFT JOIN {{ source('silver', 'si_meetings') }} m ON p.meeting_id = m.meeting_id
    WHERE p.record_status = 'ACTIVE'
),

feature_usage AS (
    SELECT 
        meeting_id,
        user_id,
        SUM(CASE WHEN feature_name = 'Screen Sharing' THEN usage_count ELSE 0 END) as screen_share_duration,
        SUM(CASE WHEN feature_name = 'Chat' THEN usage_count ELSE 0 END) as chat_messages_sent,
        COUNT(*) as interaction_count,
        MAX(CASE WHEN feature_name = 'Video' THEN 1 ELSE 0 END) as video_enabled,
        MAX(CASE WHEN feature_name LIKE '%Audio%' THEN 'Computer Audio' ELSE 'Phone' END) as audio_connection_type
    FROM {{ source('silver', 'si_feature_usage') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id, user_id
)

SELECT 
    CONCAT('PF_', pb.participant_id, '_', pb.meeting_id) as participant_fact_id,
    COALESCE(pb.meeting_id, 'UNKNOWN') as meeting_id,
    pb.participant_id,
    COALESCE(pb.user_id, 'GUEST_USER') as user_id,
    pb.join_time as join_time,
    pb.leave_time as leave_time,
    DATEDIFF('minute', pb.join_time, pb.leave_time) as attendance_duration,
    CASE WHEN pb.user_id = pb.host_id THEN 'Host' ELSE 'Participant' END as participant_role,
    COALESCE(fu.audio_connection_type, 'Computer Audio') as audio_connection_type,
    CASE WHEN fu.video_enabled = 1 THEN TRUE ELSE FALSE END as video_enabled,
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
LEFT JOIN feature_usage fu ON pb.meeting_id = fu.meeting_id AND pb.user_id = fu.user_id
