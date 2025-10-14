{{ config(
    materialized='table'
) }}

WITH feature_usage AS (
    SELECT 
        fu.meeting_id,
        fu.feature_name,
        fu.usage_count,
        DATE_TRUNC('MONTH', fu.usage_date) as summary_period,
        fu.load_date,
        fu.source_system
    FROM {{ source('silver', 'si_feature_usage') }} fu
    WHERE fu.record_status = 'ACTIVE'
        AND COALESCE(fu.usage_count, 0) > 0
),

meeting_orgs AS (
    SELECT 
        m.meeting_id,
        u.company as organization_id
    FROM {{ source('silver', 'si_meetings') }} m
    LEFT JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
),

feature_summary AS (
    SELECT 
        fu.summary_period,
        mo.organization_id,
        fu.feature_name,
        SUM(fu.usage_count) as total_usage_count,
        COUNT(DISTINCT fu.meeting_id) as unique_meetings_count,
        50.0 as adoption_rate,
        'Stable' as usage_trend,
        MAX(fu.load_date) as load_date,
        FIRST_VALUE(fu.source_system) as source_system
    FROM feature_usage fu
    LEFT JOIN meeting_orgs mo ON fu.meeting_id = mo.meeting_id
    WHERE mo.organization_id IS NOT NULL
    GROUP BY fu.summary_period, mo.organization_id, fu.feature_name
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_period', 'organization_id', 'feature_name']) }} as adoption_id,
    summary_period,
    organization_id,
    feature_name,
    total_usage_count,
    unique_meetings_count as unique_users_count,
    adoption_rate,
    usage_trend,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM feature_summary
