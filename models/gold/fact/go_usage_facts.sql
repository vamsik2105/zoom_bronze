{{ config(
    materialized='table'
) }}

-- Usage Facts transformation from Silver to Gold
SELECT 
    CONCAT('UF_', usage_id, '_', usage_date::STRING) AS usage_fact_id,
    'UNKNOWN_USER' AS user_id,
    'INDIVIDUAL' AS organization_id,
    usage_date,
    0 AS meeting_count,
    0 AS total_meeting_minutes,
    0 AS webinar_count,
    0 AS total_webinar_minutes,
    CASE WHEN feature_name = 'Recording' THEN usage_count * 0.1 ELSE 0 END AS recording_storage_gb,
    usage_count AS feature_usage_count,
    0 AS unique_participants_hosted,
    load_date,
    CURRENT_DATE() AS update_date,
    source_system
FROM SILVER.si_feature_usage
WHERE record_status = 'ACTIVE'
