-- Bronze layer transformation for meetings data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_meetings', CURRENT_TIMESTAMP(), CURRENT_USER(), 0, 'STARTED')",
    post_hook = "INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_meetings', CURRENT_TIMESTAMP(), CURRENT_USER(), 0, 'SUCCESS')"
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
