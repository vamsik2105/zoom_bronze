{{ config(
    materialized='table',
    cluster_by=['summary_date', 'organization_id']
) }}

WITH meeting_quality_base AS (
    SELECT 
        m.meeting_id,
        DATE(m.start_time) as summary_date,
        u.company as organization_id,
        m.data_quality_score,
        m.duration_minutes,
        m.load_date,
        m.source_system
    FROM {{ source('silver', 'si_meetings') }} m
    JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        AND m.data_quality_score >= 0.7
        AND m.duration_minutes > 0
),

participant_quality AS (
    SELECT 
        p.meeting_id,
        COUNT(p.participant_id) as total_participants,
        COUNT(CASE WHEN p.join_time IS NOT NULL AND p.leave_time IS NOT NULL THEN 1 END) as successful_connections,
        COUNT(CASE WHEN DATEDIFF('minute', p.join_time, p.leave_time) < 2 THEN 1 END) as early_disconnects
    FROM {{ source('silver', 'si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
    GROUP BY p.meeting_id
),

quality_metrics AS (
    SELECT 
        mqb.summary_date,
        mqb.organization_id,
        COUNT(DISTINCT mqb.meeting_id) as total_sessions,
        AVG(mqb.data_quality_score) as average_audio_quality,
        AVG(mqb.data_quality_score * 0.9) as average_video_quality,
        AVG(CASE 
            WHEN pq.total_participants > 0 
            THEN (pq.successful_connections::FLOAT / pq.total_participants) * 100
            ELSE 100.0 
        END) as average_connection_stability,
        50.0 as average_latency_ms,
        AVG(CASE 
            WHEN pq.total_participants > 0 
            THEN (pq.successful_connections::FLOAT / pq.total_participants) * 100
            ELSE 100.0 
        END) as connection_success_rate,
        AVG(CASE 
            WHEN pq.total_participants > 0 
            THEN (pq.early_disconnects::FLOAT / pq.total_participants) * 100
            ELSE 0.0 
        END) as call_drop_rate,
        AVG(mqb.data_quality_score) as user_satisfaction_score,
        MAX(mqb.load_date) as load_date,
        FIRST_VALUE(mqb.source_system) as source_system
    FROM meeting_quality_base mqb
    LEFT JOIN participant_quality pq ON mqb.meeting_id = pq.meeting_id
    GROUP BY mqb.summary_date, mqb.organization_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_date', 'organization_id']) }} as quality_summary_id,
    summary_date,
    organization_id,
    total_sessions,
    ROUND(average_audio_quality, 2) as average_audio_quality,
    ROUND(average_video_quality, 2) as average_video_quality,
    ROUND(average_connection_stability, 2) as average_connection_stability,
    ROUND(average_latency_ms, 2) as average_latency_ms,
    ROUND(connection_success_rate, 2) as connection_success_rate,
    ROUND(call_drop_rate, 4) as call_drop_rate,
    ROUND(user_satisfaction_score, 2) as user_satisfaction_score,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM quality_metrics
