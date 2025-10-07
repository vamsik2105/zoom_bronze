-- Bronze layer transformation for webinars data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "{{ log_audit_start('bz_webinars') }}",
    post_hook = "{{ log_audit_end('bz_webinars', True) }}"
) }}

SELECT
    -- Direct 1:1 mapping from source
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    registrants,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'webinars') }}
