{{ config(
    materialized='table',
    pre_hook=[
      "{{ log_audit_start('bz_webinars') }}"
    ],
    post_hook=[
      "{{ log_audit_end('bz_webinars') }}"
    ]
) }}

-- Bronze layer transformation for webinars table
-- This model performs a 1:1 mapping from raw to bronze layer
WITH source_data AS (
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'webinars') }}
)

SELECT
    -- Direct mapping of fields from source to target
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    registrants,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
