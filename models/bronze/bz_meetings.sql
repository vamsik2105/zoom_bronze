{{config(
  materialized = 'table'
)}}

-- Pre-hook to log the start of processing
{% set source_table = 'meetings' %}
{{ config(
  pre_hook="{{ log_audit_start('" ~ source_table ~ "') }}"
) }}

-- Post-hook to log the end of processing
{{ config(
  post_hook="{{ log_audit_end('" ~ source_table ~ "', 'SUCCESS') }}"
) }}

-- Transform raw meetings data to bronze layer
SELECT
  meeting_id,
  host_id,
  meeting_topic,
  start_time,
  end_time,
  duration_minutes,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'meetings') }}
