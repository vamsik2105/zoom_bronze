{{ config(
    materialized='table'
) }}

-- Participant Facts transformation from Silver to Gold
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
    FROM {{ source('silver_schema', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
      AND COALESCE(data_quality_score, 0) >= 0.7
      AND join_time IS NOT NULL
      AND leave_time IS NOT NULL
),

participant_facts_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['participant_id', 'meeting_id']) }} AS participant_fact_id,
        p.meeting_id,
        p.participant_id,
        p.user_id,
        p.join_time,
        p.leave_time,
        DATEDIFF('minute', p.join_time, p.leave_time) AS attendance_duration,
        'Attendee' AS participant_role,
        'VoIP' AS audio_connection_type,
        TRUE AS video_enabled,
        0 AS screen_share_duration,
        0 AS chat_messages_sent,
        0 AS interaction_count,
        COALESCE(p.data_quality_score, 0.0) AS connection_quality_rating,
        'Desktop' AS device_type,
        'Unknown' AS geographic_location,
        p.load_date,
        p.update_date,
        p.source_system
    FROM silver_participants p
)

SELECT * FROM participant_facts_final
