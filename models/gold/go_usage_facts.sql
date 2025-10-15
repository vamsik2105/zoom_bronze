{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date) VALUES (CONCAT('PROC_UF_', CURRENT_TIMESTAMP()::STRING), 'Usage Facts Processing', 'si_feature_usage', 'go_usage_facts', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_DATE())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}) WHERE process_name = 'Usage Facts Processing' AND process_status = 'STARTED'"
) }}

WITH user_base AS (
    SELECT 
        user_id,
        company
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
),

usage_dates AS (
    SELECT DISTINCT usage_date
    FROM {{ source('silver', 'si_feature_usage') }}
    WHERE record_status = 'ACTIVE'
),

user_usage_cross AS (
    SELECT 
        ub.user_id,
        ub.company,
        ud.usage_date
    FROM user_base ub
    CROSS JOIN usage_dates ud
),

meeting_metrics AS (
    SELECT 
        host_id as user_id,
        DATE(start_time) as usage_date,
        COUNT(DISTINCT meeting_id) as meeting_count,
        SUM(duration_minutes) as total_meeting_minutes
    FROM {{ source('silver', 'si_meetings') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY host_id, DATE(start_time)
),

webinar_metrics AS (
    SELECT 
        host_id as user_id,
        DATE(start_time) as usage_date,
        COUNT(DISTINCT webinar_id) as webinar_count,
        SUM(DATEDIFF('minute', start_time, end_time)) as total_webinar_minutes
    FROM {{ source('silver', 'si_webinars') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY host_id, DATE(start_time)
),

feature_metrics AS (
    SELECT 
        meeting_id,
        usage_date,
        SUM(CASE WHEN feature_name = 'Recording' THEN usage_count * 0.1 ELSE 0 END) as recording_storage_gb,
        SUM(usage_count) as feature_usage_count
    FROM {{ source('silver', 'si_feature_usage') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id, usage_date
),

participant_metrics AS (
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
    CONCAT('UF_', uuc.user_id, '_', uuc.usage_date::STRING) as usage_fact_id,
    uuc.user_id,
    COALESCE(uuc.company, 'INDIVIDUAL') as organization_id,
    uuc.usage_date,
    COALESCE(mm.meeting_count, 0) as meeting_count,
    COALESCE(mm.total_meeting_minutes, 0) as total_meeting_minutes,
    COALESCE(wm.webinar_count, 0) as webinar_count,
    COALESCE(wm.total_webinar_minutes, 0) as total_webinar_minutes,
    COALESCE(fm.recording_storage_gb, 0) as recording_storage_gb,
    COALESCE(fm.feature_usage_count, 0) as feature_usage_count,
    COALESCE(pm.unique_participants_hosted, 0) as unique_participants_hosted,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_ANALYTICS' as source_system
FROM user_usage_cross uuc
LEFT JOIN meeting_metrics mm ON uuc.user_id = mm.user_id AND uuc.usage_date = mm.usage_date
LEFT JOIN webinar_metrics wm ON uuc.user_id = wm.user_id AND uuc.usage_date = wm.usage_date
LEFT JOIN feature_metrics fm ON uuc.usage_date = fm.usage_date
LEFT JOIN participant_metrics pm ON uuc.user_id = pm.user_id AND uuc.usage_date = pm.usage_date
WHERE (mm.meeting_count > 0 OR wm.webinar_count > 0 OR fm.feature_usage_count > 0)
