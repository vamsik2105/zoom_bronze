{{ config(
    materialized='table'
) }}

WITH user_meetings AS (
    SELECT 
        m.host_id as user_id,
        u.company as organization_id,
        DATE_TRUNC('MONTH', m.start_time) as activity_month,
        COUNT(DISTINCT m.meeting_id) as meetings_hosted,
        SUM(m.duration_minutes) as total_hosting_minutes,
        AVG(m.data_quality_score) as avg_hosting_quality,
        MAX(u.load_date) as load_date,
        FIRST_VALUE(u.source_system) as source_system
    FROM {{ source('silver', 'si_meetings') }} m
    LEFT JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        AND COALESCE(m.data_quality_score, 0) >= 0.7
        AND COALESCE(m.duration_minutes, 0) > 0
    GROUP BY m.host_id, u.company, DATE_TRUNC('MONTH', m.start_time)
),

user_participation AS (
    SELECT 
        p.user_id,
        DATE_TRUNC('MONTH', p.join_time) as activity_month,
        COUNT(DISTINCT p.meeting_id) as meetings_attended,
        SUM(DATEDIFF('minute', p.join_time, p.leave_time)) as total_attendance_minutes
    FROM {{ source('silver', 'si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
        AND p.join_time IS NOT NULL
        AND p.leave_time IS NOT NULL
    GROUP BY p.user_id, DATE_TRUNC('MONTH', p.join_time)
),

user_webinars AS (
    SELECT 
        w.host_id as user_id,
        DATE_TRUNC('MONTH', w.start_time) as activity_month,
        COUNT(DISTINCT w.webinar_id) as webinars_hosted
    FROM {{ source('silver', 'si_webinars') }} w
    WHERE w.record_status = 'ACTIVE'
    GROUP BY w.host_id, DATE_TRUNC('MONTH', w.start_time)
),

monthly_activity AS (
    SELECT 
        um.user_id,
        um.organization_id,
        um.activity_month,
        COALESCE(um.meetings_hosted, 0) as meetings_hosted,
        COALESCE(up.meetings_attended, 0) as meetings_attended,
        COALESCE(um.total_hosting_minutes, 0) as total_hosting_minutes,
        COALESCE(up.total_attendance_minutes, 0) as total_attendance_minutes,
        COALESCE(uw.webinars_hosted, 0) as webinars_hosted,
        0 as webinars_attended,
        0 as recordings_created,
        0.0 as storage_used_gb,
        0 as unique_participants_interacted,
        COALESCE(um.avg_hosting_quality, 0.0) as average_meeting_quality,
        um.load_date,
        um.source_system
    FROM user_meetings um
    LEFT JOIN user_participation up ON um.user_id = up.user_id AND um.activity_month = up.activity_month
    LEFT JOIN user_webinars uw ON um.user_id = uw.user_id AND um.activity_month = uw.activity_month
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
