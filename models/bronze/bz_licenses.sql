{{config(
  materialized = 'table',
  pre_hook="{{ log_audit_start('bz_licenses') }}",
  post_hook="{{ log_audit_end('bz_licenses') }}"
)}}

-- Transform raw licenses data to bronze layer
SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'licenses') }}
