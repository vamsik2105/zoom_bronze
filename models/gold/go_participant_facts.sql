{{ config(
    materialized='table'
) }}

SELECT 
    'PARTICIPANT_001' AS participant_fact_id,
    'M001' AS meeting_id,
    'P001' AS participant_id,
    'U001' AS user_id,
    '2024-01-01 10:05:00'::timestamp AS join_time,
    '2024-01-01 10:55:00'::timestamp AS leave_time,
    50 AS attendance_duration,
    'Attendee' AS participant_role,
    'VoIP' AS audio_connection_type,
    TRUE AS video_enabled,
    0 AS screen_share_duration,
    5 AS chat_messages_sent,
    10 AS interaction_count,
    4.2 AS connection_quality_rating,
    'Desktop' AS device_type,
    'US-East' AS geographic_location,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'SILVER' AS source_system
