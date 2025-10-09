{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_table_processing_start('participants') }}",
  post_hook="{{ log_table_processing_complete('participants') }}"
)}}

-- Transform raw participants data to bronze layer
SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'participants') }}
