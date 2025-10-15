{{ config(
    materialized='table'
) }}

-- Meeting Facts transformation from Silver to Gold
WITH silver_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        load_date,
        update_date,
        data_quality_score,
        record_status
    FROM {{ source('silver_schema', 'si_meetings') }}
    WHERE record_status = 'ACTIVE'
      AND COALESCE(data_quality_score, 0) >= 0.7
      AND start_time IS NOT NULL
      AND end_time IS NOT NULL
),

silver_participants AS (
    SELECT 
        meeting_id,
        COUNT(DISTINCT participant_id) AS participant_count,
        COUNT(DISTINCT user_id) AS unique_participants,
        SUM(DATEDIFF('minute', join_time, leave_time)) AS total_attendance_minutes,
        AVG(DATEDIFF('minute', join_time, leave_time)) AS average_attendance_duration
    FROM {{ source('silver_schema', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
      AND join_time IS NOT NULL
      AND leave_time IS NOT NULL
    GROUP BY meeting_id
),

silver_feature_usage AS (
    SELECT 
        meeting_id,
        SUM(CASE WHEN feature_name = 'screen_share' THEN usage_count ELSE 0 END) AS screen_share_count,
        SUM(CASE WHEN feature_name = 'chat' THEN usage_count ELSE 0 END) AS chat_message_count,
        SUM(CASE WHEN feature_name = 'breakout_rooms' THEN usage_count ELSE 0 END) AS breakout_room_count
    FROM {{ source('silver_schema', 'si_feature_usage') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
),

meeting_facts_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['m.meeting_id']) }} AS meeting_fact_id,
        m.meeting_id,
        m.host_id,
        COALESCE(m.meeting_topic, 'Untitled Meeting') AS meeting_topic,
        m.start_time,
        m.end_time,
        m.duration_minutes,
        COALESCE(p.participant_count, 0) AS participant_count,
        COALESCE(p.participant_count, 0) AS max_concurrent_participants,
        COALESCE(p.total_attendance_minutes, 0) AS total_attendance_minutes,
        COALESCE(p.average_attendance_duration, 0) AS average_attendance_duration,
        'Regular Meeting' AS meeting_type,
        'Completed' AS meeting_status,
        FALSE AS recording_enabled,
        COALESCE(f.screen_share_count, 0) AS screen_share_count,
        COALESCE(f.chat_message_count, 0) AS chat_message_count,
        COALESCE(f.breakout_room_count, 0) AS breakout_room_count,
        COALESCE(m.data_quality_score, 0.0) AS quality_score_avg,
        CASE 
            WHEN p.participant_count > 10 AND f.chat_message_count > 5 THEN 4.5
            WHEN p.participant_count > 5 AND f.chat_message_count > 2 THEN 3.5
            WHEN p.participant_count > 2 THEN 2.5
            ELSE 1.5
        END AS engagement_score,
        m.load_date,
        m.update_date,
        m.source_system
    FROM silver_meetings m
    LEFT JOIN silver_participants p ON m.meeting_id = p.meeting_id
    LEFT JOIN silver_feature_usage f ON m.meeting_id = f.meeting_id
)

SELECT * FROM meeting_facts_final
