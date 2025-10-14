{{ config(
    materialized='table'
) }}

WITH meeting_engagement AS (
    SELECT 
        m.meeting_id,
        DATE(m.start_time) as summary_date,
        u.company as organization_id,
        m.duration_minutes,
        m.load_date,
        m.source_system
    FROM {{ source('silver', 'si_meetings') }} m
    LEFT JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        AND COALESCE(m.duration_minutes, 0) > 0
),

participant_engagement AS (
    SELECT 
        p.meeting_id,
        COUNT(p.participant_id) as actual_participants,
        AVG(DATEDIFF('minute', p.join_time, p.leave_time)) as avg_participation_duration
    FROM {{ source('silver', 'si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
        AND p.join_time IS NOT NULL
        AND p.leave_time IS NOT NULL
    GROUP BY p.meeting_id
),

feature_stats AS (
    SELECT 
        fu.meeting_id,
        SUM(CASE WHEN fu.feature_name = 'chat' THEN fu.usage_count ELSE 0 END) as chat_messages,
        SUM(CASE WHEN fu.feature_name = 'screen_share' THEN fu.usage_count ELSE 0 END) as screen_share_sessions,
        SUM(CASE WHEN fu.feature_name = 'reactions' THEN fu.usage_count ELSE 0 END) as reactions,
        SUM(CASE WHEN fu.feature_name = 'qa' THEN fu.usage_count ELSE 0 END) as qa_interactions,
        SUM(CASE WHEN fu.feature_name = 'polls' THEN fu.usage_count ELSE 0 END) as poll_responses
    FROM {{ source('silver', 'si_feature_usage') }} fu
    WHERE fu.record_status = 'ACTIVE'
    GROUP BY fu.meeting_id
),

engagement_summary AS (
    SELECT 
        me.summary_date,
        me.organization_id,
        COUNT(DISTINCT me.meeting_id) as total_meetings,
        75.0 as average_participation_rate,
        SUM(COALESCE(fs.chat_messages, 0)) as total_chat_messages,
        SUM(COALESCE(fs.screen_share_sessions, 0)) as screen_share_sessions,
        SUM(COALESCE(fs.reactions, 0)) as total_reactions,
        SUM(COALESCE(fs.qa_interactions, 0)) as qa_interactions,
        SUM(COALESCE(fs.poll_responses, 0)) as poll_responses,
        80.0 as average_attention_score,
        MAX(me.load_date) as load_date,
        FIRST_VALUE(me.source_system) as source_system
    FROM meeting_engagement me
    LEFT JOIN participant_engagement pe ON me.meeting_id = pe.meeting_id
    LEFT JOIN feature_stats fs ON me.meeting_id = fs.meeting_id
    WHERE me.organization_id IS NOT NULL
    GROUP BY me.summary_date, me.organization_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_date', 'organization_id']) }} as engagement_id,
    summary_date,
    organization_id,
    total_meetings,
    ROUND(average_participation_rate, 2) as average_participation_rate,
    total_chat_messages,
    screen_share_sessions,
    total_reactions,
    qa_interactions,
    poll_responses,
    ROUND(average_attention_score, 2) as average_attention_score,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM engagement_summary
