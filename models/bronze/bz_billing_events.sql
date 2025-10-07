{{config(
  materialized = 'table',
  pre_hook="{{ log_audit_start('bz_billing_events') }}",
  post_hook="{{ log_audit_end('bz_billing_events') }}"
)}}

-- Transform raw billing events data to bronze layer
SELECT
  event_id,
  user_id,
  event_type,
  amount,
  event_date,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'billing_events') }}
