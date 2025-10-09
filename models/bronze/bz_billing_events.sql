{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_table_processing_start('billing_events') }}",
  post_hook="{{ log_table_processing_complete('billing_events') }}"
)}}

-- Transform raw billing_events data to bronze layer
SELECT
  event_id,
  user_id,
  event_type,
  amount,
  event_date,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'billing_events') }}
