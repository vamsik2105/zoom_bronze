{{ config(
    materialized='table'
) }}

WITH source_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver', 'si_meetings') }}
    WHERE meeting_id IS NOT NULL
),

participant_stats AS (
    SELECT 
        p.meeting_id,
        COUNT(DISTINCT p.participant_id) as participant_count,
        COUNT(DISTINCT p.participant_id) as max_concurrent_participants,
        SUM(DATEDIFF('minute', p.join_time, p.leave_time)) as total_attendance_minutes,
        AVG(DATEDIFF('minute', p.join_time, p.leave_time)) as average_attendance_duration
    FROM {{ source('silver', 'si_participants') }} p
    WHERE p.meeting_id IS NOT NULL
      AND p.join_time IS NOT NULL
      AND p.leave_time IS NOT NULL
    GROUP BY p.meeting_id
),

final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['m.meeting_id']) }} as meeting_fact_id,
        m.meeting_id,
        m.host_id,
        m.meeting_topic,
        m.start_time,
        m.end_time,
        m.duration_minutes,
        COALESCE(ps.participant_count, 0) as participant_count,
        COALESCE(ps.max_concurrent_participants, 0) as max_concurrent_participants,
        COALESCE(ps.total_attendance_minutes, 0) as total_attendance_minutes,
        COALESCE(ps.average_attendance_duration, 0) as average_attendance_duration,
        'Regular Meeting' as meeting_type,
        'Completed' as meeting_status,
        FALSE as recording_enabled,
        0 as screen_share_count,
        0 as chat_message_count,
        0 as breakout_room_count,
        85.5 as quality_score_avg,
        75.0 as engagement_score,
        m.load_date,
        m.update_date,
        m.source_system
    FROM source_meetings m
    LEFT JOIN participant_stats ps ON m.meeting_id = ps.meeting_id
)

SELECT * FROM final
