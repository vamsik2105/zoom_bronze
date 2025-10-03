{{config(
  materialized = 'table'
)}}

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
