{{ config(
    materialized='table'
) }}

SELECT 
    participant_id as participant_fact_id,
    meeting_id,
    participant_id,
    user_id,
    join_time,
    leave_time,
    0 as attendance_duration,
    'Participant' as participant_role,
    'Computer Audio' as audio_connection_type,
    FALSE as video_enabled,
    0 as screen_share_duration,
    0 as chat_messages_sent,
    0 as interaction_count,
    data_quality_score as connection_quality_rating,
    'Desktop' as device_type,
    'Unknown' as geographic_location,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM SILVER.si_participants
WHERE record_status = 'ACTIVE'
