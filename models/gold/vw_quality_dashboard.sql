{{ config(
    materialized='view'
) }}

SELECT 
    qms.summary_date,
    qms.organization_id as organization_name,
    qms.total_sessions,
    qms.average_audio_quality,
    qms.average_video_quality,
    qms.connection_success_rate,
    qms.user_satisfaction_score,
    qms.average_latency_ms
FROM {{ ref('go_quality_metrics_summary') }} qms
