{{ config(
    materialized='table'
) }}

SELECT 
    participant_id as quality_fact_id,
    meeting_id,
    participant_id,
    participant_id as device_connection_id,
    data_quality_score as audio_quality_score,
    data_quality_score as video_quality_score,
    data_quality_score as connection_stability_rating,
    100 as latency_ms,
    0.05 as packet_loss_rate,
    50 as bandwidth_utilization,
    50.0 as cpu_usage_percentage,
    100 as memory_usage_mb,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM SILVER.si_participants
LIMIT 100
