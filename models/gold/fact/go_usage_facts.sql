{{ config(
    materialized='table',
    cluster_by=['usage_date', 'organization_id']
) }}

-- Usage Facts transformation from Silver to Gold
WITH user_organizations AS (
    SELECT 
        user_id,
        company AS organization_id
    FROM {{ source('silver', 'si_users') }}
    WHERE record_status = 'ACTIVE'
),

meeting_usage AS (
    SELECT 
        host_id AS user_id,
        DATE(start_time) AS usage_date,
        COUNT(DISTINCT meeting_id) AS meeting_count,
        SUM(duration_minutes) AS total_meeting_minutes
    FROM {{ source('silver', 'si_meetings') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY host_id, DATE(start_time)
),

webinar_usage AS (
    SELECT 
        host_id AS user_id,
        DATE(start_time) AS usage_date,
        COUNT(DISTINCT webinar_id) AS webinar_count,
        SUM(DATEDIFF('minute', start_time, end_time)) AS total_webinar_minutes
    FROM {{ source('silver', 'si_webinars') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY host_id, DATE(start_time)
),

feature_usage_summary AS (
    SELECT 
        usage_date,
        SUM(usage_count) AS feature_usage_count,
        SUM(CASE WHEN feature_name = 'Recording' THEN usage_count * 0.1 ELSE 0 END) AS recording_storage_gb
    FROM {{ source('silver', 'si_feature_usage') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY usage_date
),

participant_interactions AS (
    SELECT 
        DATE(join_time) AS usage_date,
        COUNT(DISTINCT user_id) AS unique_participants_hosted
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY DATE(join_time)
),

all_usage_dates AS (
    SELECT DISTINCT usage_date, user_id FROM meeting_usage
    UNION
    SELECT DISTINCT usage_date, user_id FROM webinar_usage
),

final_transform AS (
    SELECT 
        CONCAT('UF_', aud.user_id, '_', aud.usage_date::STRING) AS usage_fact_id,
        aud.user_id,
        COALESCE(uo.organization_id, 'INDIVIDUAL') AS organization_id,
        aud.usage_date,
        COALESCE(mu.meeting_count, 0) AS meeting_count,
        COALESCE(mu.total_meeting_minutes, 0) AS total_meeting_minutes,
        COALESCE(wu.webinar_count, 0) AS webinar_count,
        COALESCE(wu.total_webinar_minutes, 0) AS total_webinar_minutes,
        COALESCE(fus.recording_storage_gb, 0) AS recording_storage_gb,
        COALESCE(fus.feature_usage_count, 0) AS feature_usage_count,
        COALESCE(pi.unique_participants_hosted, 0) AS unique_participants_hosted,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'Zoom_Analytics' AS source_system
    FROM all_usage_dates aud
    LEFT JOIN user_organizations uo ON aud.user_id = uo.user_id
    LEFT JOIN meeting_usage mu ON aud.user_id = mu.user_id AND aud.usage_date = mu.usage_date
    LEFT JOIN webinar_usage wu ON aud.user_id = wu.user_id AND aud.usage_date = wu.usage_date
    LEFT JOIN feature_usage_summary fus ON aud.usage_date = fus.usage_date
    LEFT JOIN participant_interactions pi ON aud.usage_date = pi.usage_date
)

SELECT * FROM final_transform
