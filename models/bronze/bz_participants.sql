{{config(
  materialized = 'table'
)}}

-- Pre-hook to log the start of processing
{% set source_table = 'participants' %}
{{ config(
  pre_hook="{{ log_audit_start('" ~ source_table ~ "') }}"
) }}

-- Post-hook to log the end of processing
{{ config(
  post_hook="{{ log_audit_end('" ~ source_table ~ "', 'SUCCESS') }}"
) }}

-- Transform raw participants data to bronze layer
SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'participants') }}
