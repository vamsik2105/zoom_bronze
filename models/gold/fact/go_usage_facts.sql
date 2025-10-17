{{ config(
    materialized='table',
    cluster_by=['usage_date', 'organization_id']
) }}

WITH user_base AS (
    SELECT 
        u.user_id,
        COALESCE(u.company, 'INDIVIDUAL') as organization_id
    FROM {{ source('silver', 'si_users') }} u
    WHERE u.record_status = 'ACTIVE'
),

meeting_usage AS (
    SELECT 
        m.host_id as user_id,
        DATE(m.start_time) as usage_date,
        COUNT(DISTINCT m.meeting_id) as meeting_count,
        SUM(m.duration_minutes) as total_meeting_minutes
    FROM {{ source('silver', 'si_meetings') }} m
    WHERE m.record_status = 'ACTIVE'
    GROUP BY m.host_id, DATE(m.start_time)
),

webinar_usage AS (
    SELECT 
        w.host_id as user_id,
        DATE(w.start_time) as usage_date,
        COUNT(DISTINCT w.webinar_id) as webinar_count,
        SUM(DATEDIFF('minute', w.start_time, w.end_time)) as total_webinar_minutes
    FROM {{ source('silver', 'si_webinars') }} w
    WHERE w.record_status = 'ACTIVE'
    GROUP BY w.host_id, DATE(w.start_time)
),

feature_usage_summary AS (
    SELECT 
        f.usage_date,
        u.user_id,
        SUM(f.usage_count) as feature_usage_count,
        SUM(CASE WHEN f.feature_name = 'Recording' THEN f.usage_count * 0.1 ELSE 0 END) as recording_storage_gb
    FROM {{ source('silver', 'si_feature_usage') }} f
    JOIN user_base u ON TRUE
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.usage_date, u.user_id
),

participant_interactions AS (
    SELECT 
        m.host_id as user_id,
        DATE(p.join_time) as usage_date,
        COUNT(DISTINCT p.user_id) as unique_participants_hosted
    FROM {{ source('silver', 'si_participants') }} p
    JOIN {{ source('silver', 'si_meetings') }} m ON p.meeting_id = m.meeting_id
    WHERE p.record_status = 'ACTIVE' AND m.record_status = 'ACTIVE'
    GROUP BY m.host_id, DATE(p.join_time)
)

SELECT 
    CONCAT('UF_', ub.user_id, '_', COALESCE(mu.usage_date, wu.usage_date, fus.usage_date, pi.usage_date)::STRING) as usage_fact_id,
    ub.user_id,
    ub.organization_id,
    COALESCE(mu.usage_date, wu.usage_date, fus.usage_date, pi.usage_date) as usage_date,
    COALESCE(mu.meeting_count, 0) as meeting_count,
    COALESCE(mu.total_meeting_minutes, 0) as total_meeting_minutes,
    COALESCE(wu.webinar_count, 0) as webinar_count,
    COALESCE(wu.total_webinar_minutes, 0) as total_webinar_minutes,
    COALESCE(fus.recording_storage_gb, 0) as recording_storage_gb,
    COALESCE(fus.feature_usage_count, 0) as feature_usage_count,
    COALESCE(pi.unique_participants_hosted, 0) as unique_participants_hosted,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SILVER' as source_system
FROM user_base ub
LEFT JOIN meeting_usage mu ON ub.user_id = mu.user_id
LEFT JOIN webinar_usage wu ON ub.user_id = wu.user_id AND mu.usage_date = wu.usage_date
LEFT JOIN feature_usage_summary fus ON ub.user_id = fus.user_id AND COALESCE(mu.usage_date, wu.usage_date) = fus.usage_date
LEFT JOIN participant_interactions pi ON ub.user_id = pi.user_id AND COALESCE(mu.usage_date, wu.usage_date, fus.usage_date) = pi.usage_date
WHERE COALESCE(mu.usage_date, wu.usage_date, fus.usage_date, pi.usage_date) IS NOT NULL
