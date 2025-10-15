{{ config(
    materialized='table'
) }}

WITH silver_users AS (
    SELECT 
        user_id,
        company
    FROM SILVER.si_users
    WHERE record_status = 'ACTIVE'
),

silver_feature_usage AS (
    SELECT 
        usage_date,
        meeting_id,
        feature_name,
        usage_count
    FROM SILVER.si_feature_usage
    WHERE record_status = 'ACTIVE'
),

silver_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        start_time,
        duration_minutes
    FROM SILVER.si_meetings
    WHERE record_status = 'ACTIVE'
),

daily_usage AS (
    SELECT 
        sm.host_id as user_id,
        DATE(sm.start_time) as usage_date,
        COUNT(DISTINCT sm.meeting_id) as meeting_count,
        SUM(sm.duration_minutes) as total_meeting_minutes,
        0 as webinar_count,
        0 as total_webinar_minutes,
        0 as recording_storage_gb,
        0 as feature_usage_count,
        0 as unique_participants_hosted
    FROM silver_meetings sm
    GROUP BY sm.host_id, DATE(sm.start_time)
)

SELECT 
    CONCAT('UF_', du.user_id, '_', du.usage_date::STRING) as usage_fact_id,
    du.user_id,
    COALESCE(su.company, 'INDIVIDUAL') as organization_id,
    du.usage_date,
    du.meeting_count,
    du.total_meeting_minutes,
    du.webinar_count,
    du.total_webinar_minutes,
    du.recording_storage_gb,
    du.feature_usage_count,
    du.unique_participants_hosted,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_ANALYTICS' as source_system
FROM daily_usage du
LEFT JOIN silver_users su ON du.user_id = su.user_id
