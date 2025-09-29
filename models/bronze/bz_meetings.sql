{{config(
  materialized = 'table'
)}}

SELECT
  meeting_id,
  host_id,
  meeting_topic,
  start_time,
  end_time,
  duration_minutes,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'meetings') }}
