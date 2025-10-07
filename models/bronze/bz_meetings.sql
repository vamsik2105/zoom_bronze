-- Bronze layer transformation for meetings data
-- Maps raw meeting data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_meetings') }}""",
    post_hook = """{{ log_table_process_end('bz_meetings', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    Meeting_ID as meeting_id,
    Host_ID as host_id,
    Meeting_Topic as meeting_topic,
    Start_Time as start_time,
    End_Time as end_time,
    Duration_Minutes as duration_minutes,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'meetings') }}
