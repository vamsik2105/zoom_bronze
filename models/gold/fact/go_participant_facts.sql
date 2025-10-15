{{ config(
    materialized='table',
    cluster_by=['load_date', 'meeting_id']
) }}

WITH silver_participants AS (
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

silver_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time
    FROM SILVER.si_meetings
    WHERE record_status = 'ACTIVE'
),

silver_users AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type
    FROM SILVER.si_users
    WHERE record_status = 'ACTIVE'
),

silver_feature_usage AS (
    SELECT 
        meeting_id,
        feature_name,
        usage_count
    FROM SILVER.si_feature_usage
    WHERE record_status = 'ACTIVE'
),

participant_features AS (
    SELECT 
        sp.participant_id,
        sp.meeting_id,
        SUM(CASE WHEN sfu.feature_name = 'Screen Sharing' THEN sfu.usage_count ELSE 0 END) as screen_share_duration,
        SUM(CASE WHEN sfu.feature_name = 'Chat' THEN sfu.usage_count ELSE 0 END) as chat_messages_sent,
        COUNT(DISTINCT sfu.feature_name) as interaction_count,
        MAX(CASE WHEN sfu.feature_name LIKE '%Audio%' THEN 'Computer Audio' ELSE 'Phone' END) as audio_connection_type,
        MAX(CASE WHEN sfu.feature_name = 'Video' THEN TRUE ELSE FALSE END) as video_enabled
    FROM silver_participants sp
    LEFT JOIN silver_feature_usage sfu ON sp.meeting_id = sfu.meeting_id
    GROUP BY sp.participant_id, sp.meeting_id
)

SELECT 
    CONCAT('PF_', sp.participant_id, '_', sp.meeting_id) as participant_fact_id,
    COALESCE(sp.meeting_id, 'UNKNOWN') as meeting_id,
    sp.participant_id,
    COALESCE(sp.user_id, 'GUEST_USER') as user_id,
    sp.join_time as join_time,
    sp.leave_time as leave_time,
    DATEDIFF('minute', sp.join_time, COALESCE(sp.leave_time, CURRENT_TIMESTAMP())) as attendance_duration,
    CASE WHEN sp.user_id = sm.host_id THEN 'Host' ELSE 'Participant' END as participant_role,
    COALESCE(pf.audio_connection_type, 'Computer Audio') as audio_connection_type,
    COALESCE(pf.video_enabled, FALSE) as video_enabled,
    COALESCE(pf.screen_share_duration, 0) as screen_share_duration,
    COALESCE(pf.chat_messages_sent, 0) as chat_messages_sent,
    COALESCE(pf.interaction_count, 0) as interaction_count,
    ROUND(sp.data_quality_score, 2) as connection_quality_rating,
    'Desktop' as device_type,
    'Unknown' as geographic_location,
    sp.load_date,
    CURRENT_DATE() as update_date,
    sp.source_system
FROM silver_participants sp
LEFT JOIN silver_meetings sm ON sp.meeting_id = sm.meeting_id
LEFT JOIN silver_users su ON sp.user_id = su.user_id
LEFT JOIN participant_features pf ON sp.participant_id = pf.participant_id AND sp.meeting_id = pf.meeting_id
