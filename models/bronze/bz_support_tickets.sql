{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_audit_start('bz_support_tickets') }}",
  post_hook="{{ log_audit_end('bz_support_tickets') }}"
)}}

-- Transform raw support tickets data to bronze layer
SELECT
  ticket_id,
  user_id,
  ticket_type,
  resolution_status,
  open_date,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'support_tickets') }}
