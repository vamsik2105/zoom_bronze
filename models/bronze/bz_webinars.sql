{{config(
  materialized = 'table'
)}}

-- Transform raw webinars data to bronze layer
SELECT
  webinar_id,
  host_id,
  webinar_topic,
  start_time,
  end_time,
  registrants,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'webinars') }}
