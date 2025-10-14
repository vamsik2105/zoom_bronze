{{ config(
    materialized='table'
) }}

SELECT 
    'activity_001' as activity_id,
    DATE_TRUNC('MONTH', CURRENT_DATE()) as activity_month,
    'USER_001' as user_id,
    'ORG_001' as organization_id,
    0 as meetings_hosted,
    0 as meetings_attended,
    0 as total_hosting_minutes,
    0 as total_attendance_minutes,
    0 as webinars_hosted,
    0 as webinars_attended,
    0 as recordings_created,
    0.0 as storage_used_gb,
    0 as unique_participants_interacted,
    0.0 as average_meeting_quality,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SILVER' as source_system
WHERE 1=0
