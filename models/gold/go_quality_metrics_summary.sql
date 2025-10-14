{{ config(
    materialized='table'
) }}

SELECT 
    'quality_001' as quality_summary_id,
    CURRENT_DATE() as summary_date,
    'ORG_001' as organization_id,
    0 as total_sessions,
    0.0 as average_audio_quality,
    0.0 as average_video_quality,
    0.0 as average_connection_stability,
    0.0 as average_latency_ms,
    0.0 as connection_success_rate,
    0.0 as call_drop_rate,
    0.0 as user_satisfaction_score,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SILVER' as source_system
WHERE 1=0
