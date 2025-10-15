{{ config(
    materialized='table'
) }}

-- Gold Meeting Facts Table
-- Creates fact table for meeting analytics

WITH silver_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        source_system,
        load_date,
        update_date
    FROM SILVER.si_meetings
    WHERE record_status = 'ACTIVE'
      AND data_quality_score >= 0.7
),

participant_counts AS (
    SELECT 
        meeting_id,
        COUNT(DISTINCT participant_id) as participant_count,
        COUNT(DISTINCT user_id) as unique_users,
        SUM(DATEDIFF(MINUTE, join_time, leave_time)) as total_attendance_minutes
    FROM SILVER.si_participants
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
),

feature_usage_counts AS (
    SELECT 
        meeting_id,
        COUNT(DISTINCT feature_name) as features_used,
        SUM(usage_count) as total_feature_usage
    FROM SILVER.si_feature_usage
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
),

meeting_facts AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['m.meeting_id']) }} as meeting_fact_id,
        m.meeting_id,
        m.host_id,
        m.meeting_topic,
        m.start_time,
        m.end_time,
        m.duration_minutes,
        COALESCE(p.participant_count, 0) as participant_count,
        COALESCE(p.participant_count, 0) as max_concurrent_participants,
        COALESCE(p.total_attendance_minutes, 0) as total_attendance_minutes,
        CASE 
            WHEN p.participant_count > 0 THEN p.total_attendance_minutes / p.participant_count
            ELSE 0
        END as average_attendance_duration,
        'Regular' as meeting_type,
        'Completed' as meeting_status,
        FALSE as recording_enabled,
        COALESCE(f.features_used, 0) as screen_share_count,
        0 as chat_message_count,
        0 as breakout_room_count,
        85.5 as quality_score_avg,
        CASE 
            WHEN f.total_feature_usage > 10 THEN 90.0
            WHEN f.total_feature_usage > 5 THEN 75.0
            ELSE 60.0
        END as engagement_score,
        m.load_date,
        m.update_date,
        m.source_system
    FROM silver_meetings m
    LEFT JOIN participant_counts p ON m.meeting_id = p.meeting_id
    LEFT JOIN feature_usage_counts f ON m.meeting_id = f.meeting_id
)

SELECT * FROM meeting_facts
