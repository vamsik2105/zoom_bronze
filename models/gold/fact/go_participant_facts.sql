{{ config(
    materialized='table',
    cluster_by=['load_date', 'meeting_id'],
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message) VALUES (CONCAT('PF_', CURRENT_TIMESTAMP()::STRING), 'go_participant_facts_load', 'si_participants', 'go_participant_facts', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL)",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}) WHERE process_name = 'go_participant_facts_load' AND process_status = 'STARTED'"
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
    FROM {{ ref('si_participants') }} p
    LEFT JOIN {{ ref('si_meetings') }} m ON p.meeting_id = m.meeting_id
    WHERE p.record_status = 'ACTIVE'
),

participant_features AS (
    SELECT 
        f.meeting_id,
        f.usage_date,
        SUM(CASE WHEN f.feature_name = 'Screen Sharing' THEN f.usage_count ELSE 0 END) as screen_share_duration,
        SUM(CASE WHEN f.feature_name = 'Chat' THEN f.usage_count ELSE 0 END) as chat_messages_sent,
        COUNT(*) as interaction_count,
        MAX(CASE WHEN f.feature_name = 'Video' THEN 1 ELSE 0 END) as video_enabled,
        MAX(CASE WHEN f.feature_name LIKE '%Audio%' THEN 'Computer Audio' ELSE 'Phone' END) as audio_connection_type
    FROM {{ ref('si_feature_usage') }} f
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.meeting_id, f.usage_date
),

final_participant_facts AS (
    SELECT 
        CONCAT('PF_', pb.participant_id, '_', pb.meeting_id) as participant_fact_id,
        COALESCE(pb.meeting_id, 'UNKNOWN') as meeting_id,
        pb.participant_id,
        COALESCE(pb.user_id, 'GUEST_USER') as user_id,
        CONVERT_TIMEZONE('UTC', pb.join_time) as join_time,
        CONVERT_TIMEZONE('UTC', pb.leave_time) as leave_time,
        DATEDIFF('minute', pb.join_time, pb.leave_time) as attendance_duration,
        CASE 
            WHEN pb.user_id = pb.host_id THEN 'Host' 
            ELSE 'Participant' 
        END as participant_role,
        COALESCE(pf.audio_connection_type, 'Computer Audio') as audio_connection_type,
        CASE WHEN pf.video_enabled = 1 THEN TRUE ELSE FALSE END as video_enabled,
        COALESCE(pf.screen_share_duration, 0) as screen_share_duration,
        COALESCE(pf.chat_messages_sent, 0) as chat_messages_sent,
        COALESCE(pf.interaction_count, 0) as interaction_count,
        ROUND(pb.data_quality_score, 2) as connection_quality_rating,
        'Desktop' as device_type,
        'Unknown' as geographic_location,
        pb.load_date,
        CURRENT_DATE() as update_date,
        pb.source_system
    FROM participant_base pb
    LEFT JOIN participant_features pf ON pb.meeting_id = pf.meeting_id
)

SELECT * FROM final_participant_facts
