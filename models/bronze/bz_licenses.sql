{{config(
  materialized = 'table'
)}}

-- Transform raw licenses data to bronze layer
SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'licenses') }}
