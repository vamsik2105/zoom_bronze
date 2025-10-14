{{ config(
    materialized='table'
) }}

SELECT 
    'adoption_001' as adoption_id,
    DATE_TRUNC('MONTH', CURRENT_DATE()) as summary_period,
    'ORG_001' as organization_id,
    'chat' as feature_name,
    0 as total_usage_count,
    0 as unique_users_count,
    0.0 as adoption_rate,
    'Stable' as usage_trend,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SILVER' as source_system
WHERE 1=0
