{{ config(
    materialized='table'
) }}

WITH silver_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        source_system,
        load_date,
        data_quality_score
    FROM SILVER.si_participants
    WHERE record_status = 'ACTIVE'
),

silver_meetings AS (
    SELECT 
        meeting_id,
        host_id
    FROM SILVER.si_meetings
    WHERE record_status = 'ACTIVE'
)

SELECT 
    CONCAT('PF_', sp.participant_id, '_', sp.meeting_id) as participant_fact_id,
    sp.meeting_id,
    sp.participant_id,
    COALESCE(sp.user_id, 'GUEST_USER') as user_id,
    sp.join_time,
    sp.leave_time,
    DATEDIFF('minute', sp.join_time, COALESCE(sp.leave_time, CURRENT_TIMESTAMP())) as attendance_duration,
    CASE WHEN sp.user_id = sm.host_id THEN 'Host' ELSE 'Participant' END as participant_role,
    'Computer Audio' as audio_connection_type,
    FALSE as video_enabled,
    0 as screen_share_duration,
    0 as chat_messages_sent,
    0 as interaction_count,
    ROUND(sp.data_quality_score, 2) as connection_quality_rating,
    'Desktop' as device_type,
    'Unknown' as geographic_location,
    sp.load_date,
    CURRENT_DATE() as update_date,
    sp.source_system
FROM silver_participants sp
LEFT JOIN silver_meetings sm ON sp.meeting_id = sm.meeting_id
