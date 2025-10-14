{{ config(
    materialized='table',
    cluster_by=['summary_date', 'organization_id']
) }}

WITH meeting_base AS (
    SELECT 
        meeting_id,
        host_id,
        start_time,
        duration_minutes,
        data_quality_score,
        load_date,
        source_system,
        record_status
    FROM {{ source('silver', 'si_meetings') }}
    WHERE record_status = 'ACTIVE'
        AND data_quality_score >= 0.7
        AND duration_minutes > 0
),

user_org_mapping AS (
    SELECT 
        user_id,
        company as organization_id
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
),

participant_counts AS (
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

daily_aggregation AS (
    SELECT 
        DATE(mb.start_time) as summary_date,
        uom.organization_id,
        COUNT(DISTINCT mb.meeting_id) as total_meetings,
        SUM(mb.duration_minutes) as total_meeting_minutes,
        SUM(COALESCE(pc.participant_count, 0)) as total_participants,
        COUNT(DISTINCT mb.host_id) as unique_hosts,
        SUM(COALESCE(pc.unique_participant_count, 0)) as unique_participants,
        AVG(mb.duration_minutes) as average_meeting_duration,
        CASE 
            WHEN COUNT(DISTINCT mb.meeting_id) > 0 
            THEN SUM(COALESCE(pc.participant_count, 0)) / COUNT(DISTINCT mb.meeting_id)
            ELSE 0 
        END as average_participants_per_meeting,
        0 as meetings_with_recording,
        0.0 as recording_percentage,
        AVG(mb.data_quality_score) as average_quality_score,
        AVG(COALESCE(pc.participant_count, 0) * 0.8) as average_engagement_score,
        MAX(mb.load_date) as load_date,
        FIRST_VALUE(mb.source_system) as source_system
    FROM meeting_base mb
    LEFT JOIN user_org_mapping uom ON mb.host_id = uom.user_id
    LEFT JOIN participant_counts pc ON mb.meeting_id = pc.meeting_id
    WHERE uom.organization_id IS NOT NULL
    GROUP BY DATE(mb.start_time), uom.organization_id
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
FROM daily_aggregation
