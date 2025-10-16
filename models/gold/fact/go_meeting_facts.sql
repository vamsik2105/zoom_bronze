{{ config(
    materialized='table'
) }}

-- Meeting Facts transformation from Silver to Gold
SELECT 
    'MF_' || COALESCE(meeting_id, 'UNKNOWN') || '_' || CURRENT_TIMESTAMP()::STRING as meeting_fact_id,
    COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
    COALESCE(host_id, 'UNKNOWN_HOST') as host_id,
    COALESCE(TRIM(meeting_topic), 'No Topic Specified') as meeting_topic,
    start_time,
    end_time,
    COALESCE(duration_minutes, 0) as duration_minutes,
    0 as participant_count,
    0 as max_concurrent_participants,
    0 as total_attendance_minutes,
    0 as average_attendance_duration,
    CASE 
        WHEN COALESCE(duration_minutes, 0) < 15 THEN 'Quick Meeting'
        WHEN COALESCE(duration_minutes, 0) < 60 THEN 'Standard Meeting'
        ELSE 'Extended Meeting' 
    END as meeting_type,
    CASE 
        WHEN end_time IS NOT NULL THEN 'Completed'
        WHEN start_time <= CURRENT_TIMESTAMP() THEN 'In Progress'
        ELSE 'Scheduled' 
    END as meeting_status,
    FALSE as recording_enabled,
    0 as screen_share_count,
    0 as chat_message_count,
    0 as breakout_room_count,
    COALESCE(data_quality_score, 0) as quality_score_avg,
    0.0 as engagement_score,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM {{ source('silver', 'si_meetings') }}
WHERE record_status = 'ACTIVE'
