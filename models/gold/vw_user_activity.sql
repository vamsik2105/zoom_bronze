{{ config(
    materialized='view'
) }}

SELECT 
    ua.user_id,
    u.user_name,
    u.email,
    u.company as department_name,
    ua.activity_month,
    ua.meetings_hosted,
    ua.meetings_attended,
    ua.total_hosting_minutes,
    ua.total_attendance_minutes,
    ua.average_meeting_quality,
    u.company as organization_name
FROM {{ ref('go_monthly_user_activity') }} ua
LEFT JOIN {{ source('silver', 'si_users') }} u ON ua.user_id = u.user_id
WHERE u.record_status = 'ACTIVE'
