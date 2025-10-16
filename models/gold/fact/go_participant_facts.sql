{{ config(
    materialized='table',
    cluster_by=['join_time', 'meeting_id']
) }}

-- Participant Facts transformation from Silver to Gold
WITH participant_base AS (
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
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
),

meeting_hosts AS (
    SELECT 
        meeting_id,
        host_id
    FROM {{ source('silver', 'si_meetings') }}
    WHERE record_status = 'ACTIVE'
),

feature_usage_by_participant AS (
    SELECT 
        meeting_id,
        SUM(CASE WHEN feature_name = 'Screen Sharing' THEN usage_count ELSE 0 END) AS screen_share_duration,
        SUM(CASE WHEN feature_name = 'Chat' THEN usage_count ELSE 0 END) AS chat_messages_sent,
        COUNT(*) AS interaction_count,
        MAX(CASE WHEN feature_name LIKE '%Audio%' THEN 'Computer Audio' ELSE 'Phone' END) AS audio_connection_type,
        MAX(CASE WHEN feature_name = 'Video' THEN TRUE ELSE FALSE END) AS video_enabled
    FROM {{ source('silver', 'si_feature_usage') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
),

final_transform AS (
    SELECT 
        CONCAT('PF_', pb.participant_id, '_', pb.meeting_id) AS participant_fact_id,
        COALESCE(pb.meeting_id, 'UNKNOWN') AS meeting_id,
        pb.participant_id,
        COALESCE(pb.user_id, 'GUEST_USER') AS user_id,
        CONVERT_TIMEZONE('UTC', pb.join_time) AS join_time,
        CONVERT_TIMEZONE('UTC', pb.leave_time) AS leave_time,
        DATEDIFF('minute', pb.join_time, pb.leave_time) AS attendance_duration,
        CASE 
            WHEN pb.user_id = mh.host_id THEN 'Host' 
            ELSE 'Participant' 
        END AS participant_role,
        COALESCE(fup.audio_connection_type, 'Computer Audio') AS audio_connection_type,
        COALESCE(fup.video_enabled, FALSE) AS video_enabled,
        COALESCE(fup.screen_share_duration, 0) AS screen_share_duration,
        COALESCE(fup.chat_messages_sent, 0) AS chat_messages_sent,
        COALESCE(fup.interaction_count, 0) AS interaction_count,
        ROUND(pb.data_quality_score, 2) AS connection_quality_rating,
        'Desktop' AS device_type,
        'Unknown' AS geographic_location,
        pb.load_date,
        CURRENT_DATE() AS update_date,
        pb.source_system
    FROM participant_base pb
    LEFT JOIN meeting_hosts mh ON pb.meeting_id = mh.meeting_id
    LEFT JOIN feature_usage_by_participant fup ON pb.meeting_id = fup.meeting_id
)

SELECT * FROM final_transform
