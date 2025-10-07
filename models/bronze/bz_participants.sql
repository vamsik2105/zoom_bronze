{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_audit_start('bz_participants') }}",
  post_hook="{{ log_audit_end('bz_participants') }}"
)}}

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
