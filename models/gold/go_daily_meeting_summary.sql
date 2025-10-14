{{ config(
    materialized='table'
) }}

WITH meeting_data AS (
    SELECT 
        m.meeting_id,
        m.host_id,
        m.start_time,
        m.duration_minutes,
        m.data_quality_score,
        m.load_date,
        m.source_system,
        u.company as organization_id
    FROM {{ source('silver', 'si_meetings') }} m
    LEFT JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND COALESCE(m.data_quality_score, 0) >= 0.7
        AND COALESCE(m.duration_minutes, 0) > 0
        AND u.record_status = 'ACTIVE'
),

participant_data AS (
    SELECT 
        meeting_id,
        COUNT(participant_id) as participant_count,
        COUNT(DISTINCT user_id) as unique_participant_count
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
        AND join_time IS NOT NULL
        AND leave_time IS NOT NULL
    GROUP BY meeting_id
),

daily_summary AS (
    SELECT 
        DATE(md.start_time) as summary_date,
        md.organization_id,
        COUNT(DISTINCT md.meeting_id) as total_meetings,
        SUM(md.duration_minutes) as total_meeting_minutes,
        SUM(COALESCE(pd.participant_count, 0)) as total_participants,
        COUNT(DISTINCT md.host_id) as unique_hosts,
        SUM(COALESCE(pd.unique_participant_count, 0)) as unique_participants,
        AVG(md.duration_minutes) as average_meeting_duration,
        CASE 
            WHEN COUNT(DISTINCT md.meeting_id) > 0 
            THEN SUM(COALESCE(pd.participant_count, 0)) / COUNT(DISTINCT md.meeting_id)
            ELSE 0 
        END as average_participants_per_meeting,
        0 as meetings_with_recording,
        0.0 as recording_percentage,
        AVG(md.data_quality_score) as average_quality_score,
        AVG(COALESCE(pd.participant_count, 0) * 0.8) as average_engagement_score,
        MAX(md.load_date) as load_date,
        FIRST_VALUE(md.source_system) as source_system
    FROM meeting_data md
    LEFT JOIN participant_data pd ON md.meeting_id = pd.meeting_id
    WHERE md.organization_id IS NOT NULL
    GROUP BY DATE(md.start_time), md.organization_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_date', 'organization_id']) }} as summary_id,
    summary_date,
    organization_id,
    total_meetings,
    total_meeting_minutes,
    total_participants,
    unique_hosts,
    unique_participants,
    ROUND(average_meeting_duration, 2) as average_meeting_duration,
    ROUND(average_participants_per_meeting, 2) as average_participants_per_meeting,
    meetings_with_recording,
    recording_percentage,
    ROUND(average_quality_score, 2) as average_quality_score,
    ROUND(average_engagement_score, 2) as average_engagement_score,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM daily_summary
