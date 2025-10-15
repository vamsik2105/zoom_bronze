{{ config(
    materialized='table'
) }}

SELECT 
    'PF_001' as participant_fact_id,
    'MEETING_001' as meeting_id,
    'PARTICIPANT_001' as participant_id,
    'USER_001' as user_id,
    CURRENT_TIMESTAMP() as join_time,
    CURRENT_TIMESTAMP() as leave_time,
    60 as attendance_duration,
    'Participant' as participant_role,
    'Computer Audio' as audio_connection_type,
    TRUE as video_enabled,
    5 as screen_share_duration,
    3 as chat_messages_sent,
    8 as interaction_count,
    8.5 as connection_quality_rating,
    'Desktop' as device_type,
    'Unknown' as geographic_location,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_ANALYTICS' as source_system
