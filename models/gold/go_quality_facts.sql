{{ config(
    materialized='table'
) }}

WITH meeting_quality AS (
    SELECT 
        m.meeting_id,
        p.participant_id,
        'DEVICE_001' as device_connection_id,
        85.5 as audio_quality_score,
        82.0 as video_quality_score,
        88.0 as connection_stability_rating,
        45 as latency_ms,
        0.02 as packet_loss_rate,
        75 as bandwidth_utilization,
        65.5 as cpu_usage_percentage,
        512 as memory_usage_mb,
        m.load_date,
        m.update_date,
        m.source_system
    FROM {{ source('silver', 'si_meetings') }} m
    INNER JOIN {{ source('silver', 'si_participants') }} p ON m.meeting_id = p.meeting_id
    WHERE m.meeting_id IS NOT NULL
      AND p.participant_id IS NOT NULL
),

final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['meeting_id', 'participant_id']) }} as quality_fact_id,
        meeting_id,
        participant_id,
        device_connection_id,
        audio_quality_score,
        video_quality_score,
        connection_stability_rating,
        latency_ms,
        packet_loss_rate,
        bandwidth_utilization,
        cpu_usage_percentage,
        memory_usage_mb,
        load_date,
        update_date,
        source_system
    FROM meeting_quality
)

SELECT * FROM final
