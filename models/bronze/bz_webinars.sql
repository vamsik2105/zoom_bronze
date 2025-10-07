-- Bronze layer transformation for webinars data
-- Maps raw webinar data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_webinars') }}""",
    post_hook = """{{ log_table_process_end('bz_webinars', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    Webinar_ID as webinar_id,
    Host_ID as host_id,
    Webinar_Topic as webinar_topic,
    Start_Time as start_time,
    End_Time as end_time,
    Registrants as registrants,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'webinars') }}
