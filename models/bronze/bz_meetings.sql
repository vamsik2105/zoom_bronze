{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_audit_start('bz_meetings') }}",
  post_hook="{{ log_audit_end('bz_meetings') }}"
)}}

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
