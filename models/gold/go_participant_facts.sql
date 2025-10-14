{{ config(
    materialized='table'
) }}

WITH source_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_date,
        update_date,
        source_system
    FROM SILVER.si_participants
    WHERE participant_id IS NOT NULL
      AND meeting_id IS NOT NULL
),

final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['participant_id', 'meeting_id']) }} as participant_fact_id,
        meeting_id,
        participant_id,
        user_id,
        join_time,
        leave_time,
        CASE 
            WHEN join_time IS NOT NULL AND leave_time IS NOT NULL 
            THEN DATEDIFF('minute', join_time, leave_time)
            ELSE 0
        END as attendance_duration,
        'Participant' as participant_role,
        'VoIP' as audio_connection_type,
        TRUE as video_enabled,
        0 as screen_share_duration,
        0 as chat_messages_sent,
        0 as interaction_count,
        85.0 as connection_quality_rating,
        'Desktop' as device_type,
        'United States' as geographic_location,
        load_date,
        update_date,
        source_system
    FROM source_participants
)

SELECT * FROM final
