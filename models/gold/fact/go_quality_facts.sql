{{ config(
    materialized='table'
) }}

SELECT 
    CONCAT('QF_', meeting_id, '_', participant_id) as quality_fact_id,
    meeting_id,
    participant_id,
    CONCAT('DC_', participant_id, '_', CURRENT_TIMESTAMP()::STRING) as device_connection_id,
    ROUND(data_quality_score * 0.8, 2) as audio_quality_score,
    ROUND(data_quality_score * 0.9, 2) as video_quality_score,
    ROUND(data_quality_score, 2) as connection_stability_rating,
    CASE 
        WHEN data_quality_score > 8 THEN 50
        WHEN data_quality_score > 6 THEN 100
        ELSE 200
    END as latency_ms,
    CASE 
        WHEN data_quality_score > 8 THEN 0.01
        WHEN data_quality_score > 6 THEN 0.05
        ELSE 0.1
    END as packet_loss_rate,
    DATEDIFF('minute', join_time, leave_time) * 2 as bandwidth_utilization,
    CASE 
        WHEN data_quality_score > 8 THEN 25.0
        WHEN data_quality_score > 6 THEN 50.0
        ELSE 75.0
    END as cpu_usage_percentage,
    DATEDIFF('minute', join_time, leave_time) * 10 as memory_usage_mb,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM {{ source('silver', 'si_participants') }}
WHERE record_status = 'ACTIVE'
