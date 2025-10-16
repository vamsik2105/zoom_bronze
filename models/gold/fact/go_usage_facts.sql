{{ config(
    materialized='table',
    cluster_by=['load_date', 'usage_date']
) }}

-- Usage Facts transformation from Silver to Gold
WITH user_base AS (
    SELECT 
        u.user_id,
        COALESCE(u.company, 'INDIVIDUAL') as organization_id
    FROM {{ ref('si_users') }} u
    WHERE u.record_status = 'ACTIVE'
),

feature_usage_daily AS (
    SELECT 
        fu.usage_date,
        ub.user_id,
        ub.organization_id,
        SUM(fu.usage_count) as feature_usage_count,
        SUM(CASE WHEN fu.feature_name = 'Recording' THEN fu.usage_count * 0.1 ELSE 0 END) as recording_storage_gb,
        fu.load_date,
        fu.source_system
    FROM {{ ref('si_feature_usage') }} fu
    JOIN user_base ub ON fu.meeting_id IN (
        SELECT meeting_id FROM {{ ref('si_meetings') }} WHERE host_id = ub.user_id
    )
    WHERE fu.record_status = 'ACTIVE'
    GROUP BY fu.usage_date, ub.user_id, ub.organization_id, fu.load_date, fu.source_system
),

meeting_daily_stats AS (
    SELECT 
        DATE(m.start_time) as usage_date,
        m.host_id as user_id,
        COUNT(DISTINCT m.meeting_id) as meeting_count,
        SUM(m.duration_minutes) as total_meeting_minutes,
        COUNT(DISTINCT p.user_id) as unique_participants_hosted
    FROM {{ ref('si_meetings') }} m
    LEFT JOIN {{ ref('si_participants') }} p ON m.meeting_id = p.meeting_id
    WHERE m.record_status = 'ACTIVE' AND (p.record_status = 'ACTIVE' OR p.record_status IS NULL)
    GROUP BY DATE(m.start_time), m.host_id
),

webinar_daily_stats AS (
    SELECT 
        DATE(w.start_time) as usage_date,
        w.host_id as user_id,
        COUNT(DISTINCT w.webinar_id) as webinar_count,
        SUM(DATEDIFF('minute', w.start_time, w.end_time)) as total_webinar_minutes
    FROM {{ ref('si_webinars') }} w
    WHERE w.record_status = 'ACTIVE'
    GROUP BY DATE(w.start_time), w.host_id
)

SELECT 
    CONCAT('UF_', fud.user_id, '_', fud.usage_date::STRING) as usage_fact_id,
    fud.user_id,
    fud.organization_id,
    fud.usage_date,
    COALESCE(mds.meeting_count, 0) as meeting_count,
    COALESCE(mds.total_meeting_minutes, 0) as total_meeting_minutes,
    COALESCE(wds.webinar_count, 0) as webinar_count,
    COALESCE(wds.total_webinar_minutes, 0) as total_webinar_minutes,
    ROUND(fud.recording_storage_gb, 2) as recording_storage_gb,
    fud.feature_usage_count,
    COALESCE(mds.unique_participants_hosted, 0) as unique_participants_hosted,
    fud.load_date,
    CURRENT_DATE() as update_date,
    fud.source_system
FROM feature_usage_daily fud
LEFT JOIN meeting_daily_stats mds ON fud.usage_date = mds.usage_date AND fud.user_id = mds.user_id
LEFT JOIN webinar_daily_stats wds ON fud.usage_date = wds.usage_date AND fud.user_id = wds.user_id
