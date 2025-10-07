{{config(
  materialized = 'table',
  pre_hook="{{ log_audit_start('bz_users') }}",
  post_hook="{{ log_audit_end('bz_users') }}"
)}}

-- Transform raw users data to bronze layer
SELECT
  user_id,
  user_name,
  email,
  company,
  plan_type,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'users') }}
