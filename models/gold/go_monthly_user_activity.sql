{{ config(
    materialized='table',
    cluster_by=['activity_month', 'organization_id']
) }}

WITH user_base AS (
    SELECT 
        user_id,
        company as organization_id,
        load_date,
        source_system
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
),

meeting_hosting AS (
    SELECT 
        host_id as user_id,
        DATE_TRUNC('MONTH', start_time) as activity_month,
        COUNT(DISTINCT meeting_id) as meetings_hosted,
        SUM(duration_minutes) as total_hosting_minutes,
        AVG(data_quality_score) as avg_hosting_quality
    FROM {{ source('silver', 'si_meetings') }}
    WHERE record_status = 'ACTIVE'
        AND data_quality_score >= 0.7
        AND duration_minutes > 0
    GROUP BY host_id, DATE_TRUNC('MONTH', start_time)
),

meeting_attendance AS (
    SELECT 
        p.user_id,
        DATE_TRUNC('MONTH', p.join_time) as activity_month,
        COUNT(DISTINCT p.meeting_id) as meetings_attended,
        SUM(DATEDIFF('minute', p.join_time, p.leave_time)) as total_attendance_minutes,
        COUNT(DISTINCT m.host_id) as unique_hosts_interacted
    FROM {{ source('silver', 'si_participants') }} p
    JOIN {{ source('silver', 'si_meetings') }} m ON p.meeting_id = m.meeting_id
    WHERE p.record_status = 'ACTIVE'
        AND p.join_time IS NOT NULL
        AND p.leave_time IS NOT NULL
        AND m.record_status = 'ACTIVE'
    GROUP BY p.user_id, DATE_TRUNC('MONTH', p.join_time)
),

webinar_hosting AS (
    SELECT 
        host_id as user_id,
        DATE_TRUNC('MONTH', start_time) as activity_month,
        COUNT(DISTINCT webinar_id) as webinars_hosted
    FROM {{ source('silver', 'si_webinars') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY host_id, DATE_TRUNC('MONTH', start_time)
),

monthly_activity AS (
    SELECT 
        ub.user_id,
        ub.organization_id,
        COALESCE(mh.activity_month, ma.activity_month, wh.activity_month) as activity_month,
        COALESCE(mh.meetings_hosted, 0) as meetings_hosted,
        COALESCE(ma.meetings_attended, 0) as meetings_attended,
        COALESCE(mh.total_hosting_minutes, 0) as total_hosting_minutes,
        COALESCE(ma.total_attendance_minutes, 0) as total_attendance_minutes,
        COALESCE(wh.webinars_hosted, 0) as webinars_hosted,
        0 as webinars_attended,
        0 as recordings_created,
        0.0 as storage_used_gb,
        COALESCE(ma.unique_hosts_interacted, 0) as unique_participants_interacted,
        COALESCE(mh.avg_hosting_quality, 0.0) as average_meeting_quality,
        ub.load_date,
        ub.source_system
    FROM user_base ub
    LEFT JOIN meeting_hosting mh ON ub.user_id = mh.user_id
    LEFT JOIN meeting_attendance ma ON ub.user_id = ma.user_id AND mh.activity_month = ma.activity_month
    LEFT JOIN webinar_hosting wh ON ub.user_id = wh.user_id AND mh.activity_month = wh.activity_month
    WHERE COALESCE(mh.activity_month, ma.activity_month, wh.activity_month) IS NOT NULL
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['user_id', 'activity_month']) }} as activity_id,
    activity_month,
    user_id,
    organization_id,
    meetings_hosted,
    meetings_attended,
    total_hosting_minutes,
    total_attendance_minutes,
    webinars_hosted,
    webinars_attended,
    recordings_created,
    storage_used_gb,
    unique_participants_interacted,
    ROUND(average_meeting_quality, 2) as average_meeting_quality,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM monthly_activity
