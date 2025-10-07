-- Bronze layer transformation for meetings data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "{{ log_audit_start('bz_meetings') }}",
    post_hook = "{{ log_audit_end('bz_meetings', True) }}"
) }}

SELECT
    -- Direct 1:1 mapping from source
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'meetings') }}
