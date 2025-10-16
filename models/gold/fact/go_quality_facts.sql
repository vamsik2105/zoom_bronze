{{ config(
    materialized='table'
) }}

-- Quality Facts transformation from Silver to Gold
SELECT 
    'QF_SAMPLE_001' as quality_fact_id,
    'MEETING_001' as meeting_id,
    'PARTICIPANT_001' as participant_id,
    'DC_SAMPLE_001' as device_connection_id,
    8.0 as audio_quality_score,
    8.5 as video_quality_score,
    8.2 as connection_stability_rating,
    50 as latency_ms,
    0.01 as packet_loss_rate,
    120 as bandwidth_utilization,
    25.0 as cpu_usage_percentage,
    600 as memory_usage_mb,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_API' as source_system
