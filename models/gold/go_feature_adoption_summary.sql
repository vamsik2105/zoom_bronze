{{ config(
    materialized='table',
    cluster_by=['summary_period', 'organization_id']
) }}

WITH feature_usage_base AS (
    SELECT 
        fu.meeting_id,
        fu.feature_name,
        fu.usage_count,
        DATE_TRUNC('MONTH', fu.usage_date) as summary_period,
        fu.load_date,
        fu.source_system
    FROM {{ source('silver', 'si_feature_usage') }} fu
    WHERE fu.record_status = 'ACTIVE'
        AND fu.usage_count > 0
),

meeting_org_mapping AS (
    SELECT 
        m.meeting_id,
        u.company as organization_id
    FROM {{ source('silver', 'si_meetings') }} m
    JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
),

feature_aggregation AS (
    SELECT 
        fub.summary_period,
        mom.organization_id,
        fub.feature_name,
        SUM(fub.usage_count) as total_usage_count,
        COUNT(DISTINCT fub.meeting_id) as unique_meetings_count,
        MAX(fub.load_date) as load_date,
        FIRST_VALUE(fub.source_system) as source_system
    FROM feature_usage_base fub
    JOIN meeting_org_mapping mom ON fub.meeting_id = mom.meeting_id
    GROUP BY fub.summary_period, mom.organization_id, fub.feature_name
),

total_active_users AS (
    SELECT 
        DATE_TRUNC('MONTH', m.start_time) as summary_period,
        u.company as organization_id,
        COUNT(DISTINCT u.user_id) as total_users
    FROM {{ source('silver', 'si_meetings') }} m
    JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
    GROUP BY DATE_TRUNC('MONTH', m.start_time), u.company
),

feature_adoption AS (
    SELECT 
        fa.*,
        tau.total_users,
        CASE 
            WHEN tau.total_users > 0 
            THEN ROUND((fa.unique_meetings_count::FLOAT / tau.total_users) * 100, 2)
            ELSE 0.0 
        END as adoption_rate,
        'Stable' as usage_trend
    FROM feature_aggregation fa
    LEFT JOIN total_active_users tau ON fa.summary_period = tau.summary_period 
        AND fa.organization_id = tau.organization_id
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
FROM feature_adoption
