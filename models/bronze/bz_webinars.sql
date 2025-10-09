{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_table_processing_start('webinars') }}",
  post_hook="{{ log_table_processing_complete('webinars') }}"
)}}

-- Transform raw webinars data to bronze layer
SELECT
  webinar_id,
  host_id,
  webinar_topic,
  start_time,
  end_time,
  registrants,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'webinars') }}
