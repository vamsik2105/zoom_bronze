{{config(
  materialized = 'table'
)}}

SELECT
  user_id,
  user_name,
  email,
  company,
  plan_type,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'users') }}
