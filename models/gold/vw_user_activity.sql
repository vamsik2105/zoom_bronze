{{ config(
    materialized='view'
) }}

SELECT 
    'USER_001' as user_id,
    'John Doe' as user_name,
    'john.doe@example.com' as email,
    'Engineering' as department_name,
    DATE_TRUNC('MONTH', CURRENT_DATE()) as activity_month,
    5 as meetings_hosted,
    10 as meetings_attended,
    300 as total_hosting_minutes,
    600 as total_attendance_minutes,
    4.5 as average_meeting_quality,
    'Acme Corp' as organization_name
WHERE 1=0
