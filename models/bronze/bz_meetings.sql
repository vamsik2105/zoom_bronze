{{ config(
    materialized='table',
    pre_hook=[
      "{{ log_audit_start('bz_meetings') }}"
    ],
    post_hook=[
      "{{ log_audit_end('bz_meetings') }}"
    ]
) }}

-- Bronze layer transformation for meetings table
-- This model performs a 1:1 mapping from raw to bronze layer
WITH source_data AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'meetings') }}
)

SELECT
    -- Direct mapping of fields from source to target
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
