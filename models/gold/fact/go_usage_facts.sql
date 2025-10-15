{{ config(
    materialized='table',
    cluster_by=['load_date', 'usage_date']
) }}

WITH silver_users AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type
    FROM SILVER.si_users
    WHERE record_status = 'ACTIVE'
),

silver_feature_usage AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_date,
        source_system
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

silver_webinars AS (
    SELECT 
        webinar_id,
        host_id,
        start_time,
        end_time
    FROM SILVER.si_webinars
    WHERE record_status = 'ACTIVE'
),

silver_participants AS (
    SELECT 
        meeting_id,
        user_id
    FROM SILVER.si_participants
    WHERE record_status = 'ACTIVE'
),

daily_meeting_usage AS (
    SELECT 
        sm.host_id as user_id,
        DATE(sm.start_time) as usage_date,
        COUNT(DISTINCT sm.meeting_id) as meeting_count,
        SUM(sm.duration_minutes) as total_meeting_minutes
    FROM silver_meetings sm
    GROUP BY sm.host_id, DATE(sm.start_time)
),

daily_webinar_usage AS (
    SELECT 
        sw.host_id as user_id,
        DATE(sw.start_time) as usage_date,
        COUNT(DISTINCT sw.webinar_id) as webinar_count,
        SUM(DATEDIFF('minute', sw.start_time, sw.end_time)) as total_webinar_minutes
    FROM silver_webinars sw
    GROUP BY sw.host_id, DATE(sw.start_time)
),

daily_feature_usage AS (
    SELECT 
        sfu.usage_date,
        sm.host_id as user_id,
        SUM(sfu.usage_count) as feature_usage_count,
        SUM(CASE WHEN sfu.feature_name = 'Recording' THEN sfu.usage_count * 0.1 ELSE 0 END) as recording_storage_gb
    FROM silver_feature_usage sfu
    JOIN silver_meetings sm ON sfu.meeting_id = sm.meeting_id
    GROUP BY sfu.usage_date, sm.host_id
),

daily_participant_hosting AS (
    SELECT 
        sm.host_id as user_id,
        DATE(sm.start_time) as usage_date,
        COUNT(DISTINCT sp.user_id) as unique_participants_hosted
    FROM silver_meetings sm
    LEFT JOIN silver_participants sp ON sm.meeting_id = sp.meeting_id
    GROUP BY sm.host_id, DATE(sm.start_time)
),

all_usage_dates AS (
    SELECT user_id, usage_date FROM daily_meeting_usage
    UNION
    SELECT user_id, usage_date FROM daily_webinar_usage
    UNION
    SELECT user_id, usage_date FROM daily_feature_usage
    UNION
    SELECT user_id, usage_date FROM daily_participant_hosting
)

SELECT 
    CONCAT('UF_', aud.user_id, '_', aud.usage_date::STRING) as usage_fact_id,
    aud.user_id,
    COALESCE(su.company, 'INDIVIDUAL') as organization_id,
    aud.usage_date,
    COALESCE(dmu.meeting_count, 0) as meeting_count,
    COALESCE(dmu.total_meeting_minutes, 0) as total_meeting_minutes,
    COALESCE(dwu.webinar_count, 0) as webinar_count,
    COALESCE(dwu.total_webinar_minutes, 0) as total_webinar_minutes,
    COALESCE(dfu.recording_storage_gb, 0) as recording_storage_gb,
    COALESCE(dfu.feature_usage_count, 0) as feature_usage_count,
    COALESCE(dph.unique_participants_hosted, 0) as unique_participants_hosted,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_ANALYTICS' as source_system
FROM all_usage_dates aud
LEFT JOIN silver_users su ON aud.user_id = su.user_id
LEFT JOIN daily_meeting_usage dmu ON aud.user_id = dmu.user_id AND aud.usage_date = dmu.usage_date
LEFT JOIN daily_webinar_usage dwu ON aud.user_id = dwu.user_id AND aud.usage_date = dwu.usage_date
LEFT JOIN daily_feature_usage dfu ON aud.user_id = dfu.user_id AND aud.usage_date = dfu.usage_date
LEFT JOIN daily_participant_hosting dph ON aud.user_id = dph.user_id AND aud.usage_date = dph.usage_date
