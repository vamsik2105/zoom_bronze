{{config(
  materialized = 'table'
)}}

-- Transform raw participants data to bronze layer
SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'participants') }}
