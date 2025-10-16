{{ config(
    materialized='table',
    cluster_by=['load_date', 'user_id']
) }}

WITH user_base AS (
    SELECT 
        user_id,
        company,
        load_date,
        source_system
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
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

feature_usage AS (
    SELECT 
        f.usage_date,
        u.user_id,
        SUM(CASE WHEN f.feature_name = 'Recording' THEN f.usage_count * 0.1 ELSE 0 END) as recording_storage_gb,
        SUM(f.usage_count) as feature_usage_count
    FROM {{ source('silver', 'si_feature_usage') }} f
    LEFT JOIN {{ source('silver', 'si_meetings') }} m ON f.meeting_id = m.meeting_id
    LEFT JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.usage_date, u.user_id
),

participant_hosting AS (
    SELECT 
        m.host_id as user_id,
        DATE(m.start_time) as usage_date,
        COUNT(DISTINCT p.user_id) as unique_participants_hosted
    FROM {{ source('silver', 'si_meetings') }} m
    LEFT JOIN {{ source('silver', 'si_participants') }} p ON m.meeting_id = p.meeting_id
    WHERE m.record_status = 'ACTIVE' AND p.record_status = 'ACTIVE'
    GROUP BY m.host_id, DATE(m.start_time)
),

final_usage_facts AS (
    SELECT 
        CONCAT('UF_', ub.user_id, '_', fu.usage_date::STRING) as usage_fact_id,
        ub.user_id,
        COALESCE(ub.company, 'INDIVIDUAL') as organization_id,
        fu.usage_date,
        COALESCE(mu.meeting_count, 0) as meeting_count,
        COALESCE(mu.total_meeting_minutes, 0) as total_meeting_minutes,
        COALESCE(wu.webinar_count, 0) as webinar_count,
        COALESCE(wu.total_webinar_minutes, 0) as total_webinar_minutes,
        COALESCE(fu.recording_storage_gb, 0) as recording_storage_gb,
        COALESCE(fu.feature_usage_count, 0) as feature_usage_count,
        COALESCE(ph.unique_participants_hosted, 0) as unique_participants_hosted,
        ub.load_date,
        CURRENT_DATE() as update_date,
        ub.source_system
    FROM user_base ub
    CROSS JOIN (SELECT DISTINCT usage_date FROM {{ source('silver', 'si_feature_usage') }}) dates
    LEFT JOIN feature_usage fu ON ub.user_id = fu.user_id AND dates.usage_date = fu.usage_date
    LEFT JOIN meeting_usage mu ON ub.user_id = mu.user_id AND dates.usage_date = mu.usage_date
    LEFT JOIN webinar_usage wu ON ub.user_id = wu.user_id AND dates.usage_date = wu.usage_date
    LEFT JOIN participant_hosting ph ON ub.user_id = ph.user_id AND dates.usage_date = ph.usage_date
    WHERE fu.usage_date IS NOT NULL
)

SELECT * FROM final_usage_facts
