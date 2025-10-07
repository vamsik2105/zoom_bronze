-- Bronze layer transformation for meetings data

{{ config(
    materialized = 'table'
) }}

SELECT
    'meeting_1' as meeting_id,
    'host_1' as host_id,
    'Test Meeting' as meeting_topic,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    60 as duration_minutes,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
