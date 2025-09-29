{{config(
  materialized = 'table'
)}}

-- Transform raw billing events data to bronze layer
SELECT
  event_id,
  user_id,
  event_type,
  amount,
  event_date,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'billing_events') }}
