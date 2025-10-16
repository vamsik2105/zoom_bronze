{{ config(
    materialized='table'
) }}

-- Participant Facts transformation from Silver to Gold
SELECT 
    'PF_' || participant_id || '_' || meeting_id as participant_fact_id,
    COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
    participant_id,
    COALESCE(user_id, 'GUEST_USER') as user_id,
    join_time,
    leave_time,
    COALESCE(DATEDIFF('minute', join_time, leave_time), 0) as attendance_duration,
    'Participant' as participant_role,
    'Computer Audio' as audio_connection_type,
    FALSE as video_enabled,
    0 as screen_share_duration,
    0 as chat_messages_sent,
    0 as interaction_count,
    COALESCE(data_quality_score, 0) as connection_quality_rating,
    'Desktop' as device_type,
    'Unknown' as geographic_location,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM {{ source('silver', 'si_participants') }}
WHERE record_status = 'ACTIVE'
