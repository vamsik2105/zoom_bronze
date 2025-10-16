{{ config(
    materialized='table'
) }}

-- Usage Facts transformation from Silver to Gold
SELECT 
    'UF_' || usage_id || '_' || usage_date::STRING as usage_fact_id,
    'UNKNOWN_USER' as user_id,
    'INDIVIDUAL' as organization_id,
    usage_date,
    0 as meeting_count,
    0 as total_meeting_minutes,
    0 as webinar_count,
    0 as total_webinar_minutes,
    ROUND(CASE WHEN feature_name = 'Recording' THEN usage_count * 0.1 ELSE 0 END, 2) as recording_storage_gb,
    usage_count as feature_usage_count,
    0 as unique_participants_hosted,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM {{ source('silver', 'si_feature_usage') }}
WHERE record_status = 'ACTIVE'
