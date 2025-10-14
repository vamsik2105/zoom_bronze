{{ config(
    materialized='view'
) }}

SELECT 
    CURRENT_DATE() as summary_date,
    'Acme Corp' as organization_name,
    100 as total_sessions,
    4.5 as average_audio_quality,
    4.3 as average_video_quality,
    95.0 as connection_success_rate,
    4.4 as user_satisfaction_score,
    45.0 as average_latency_ms
WHERE 1=0
