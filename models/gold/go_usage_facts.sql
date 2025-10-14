{{ config(
    materialized='table'
) }}

WITH meeting_usage AS (
    SELECT 
        m.host_id as user_id,
        CAST(m.start_time AS DATE) as usage_date,
        COUNT(DISTINCT m.meeting_id) as meeting_count,
        SUM(m.duration_minutes) as total_meeting_minutes,
        COUNT(DISTINCT p.participant_id) as unique_participants_hosted
    FROM {{ source('silver', 'si_meetings') }} m
    LEFT JOIN {{ source('silver', 'si_participants') }} p ON m.meeting_id = p.meeting_id
    WHERE m.host_id IS NOT NULL
    GROUP BY m.host_id, CAST(m.start_time AS DATE)
),

webinar_usage AS (
    SELECT 
        host_id as user_id,
        CAST(start_time AS DATE) as usage_date,
        COUNT(DISTINCT webinar_id) as webinar_count,
        SUM(DATEDIFF('minute', start_time, end_time)) as total_webinar_minutes
    FROM {{ source('silver', 'si_webinars') }}
    WHERE host_id IS NOT NULL
      AND start_time IS NOT NULL
      AND end_time IS NOT NULL
    GROUP BY host_id, CAST(start_time AS DATE)
),

feature_usage AS (
    SELECT 
        'DEFAULT_USER' as user_id,
        usage_date,
        SUM(usage_count) as feature_usage_count
    FROM {{ source('silver', 'si_feature_usage') }}
    WHERE usage_date IS NOT NULL
    GROUP BY usage_date
),

final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['COALESCE(m.user_id, w.user_id, f.user_id)', 'COALESCE(m.usage_date, w.usage_date, f.usage_date)']) }} as usage_fact_id,
        COALESCE(m.user_id, w.user_id, f.user_id) as user_id,
        'ORG_001' as organization_id,
        COALESCE(m.usage_date, w.usage_date, f.usage_date) as usage_date,
        COALESCE(m.meeting_count, 0) as meeting_count,
        COALESCE(m.total_meeting_minutes, 0) as total_meeting_minutes,
        COALESCE(w.webinar_count, 0) as webinar_count,
        COALESCE(w.total_webinar_minutes, 0) as total_webinar_minutes,
        0.0 as recording_storage_gb,
        COALESCE(f.feature_usage_count, 0) as feature_usage_count,
        COALESCE(m.unique_participants_hosted, 0) as unique_participants_hosted,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'SYSTEM' as source_system
    FROM meeting_usage m
    FULL OUTER JOIN webinar_usage w ON m.user_id = w.user_id AND m.usage_date = w.usage_date
    FULL OUTER JOIN feature_usage f ON COALESCE(m.usage_date, w.usage_date) = f.usage_date
)

SELECT * FROM final
