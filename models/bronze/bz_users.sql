{{config(
  materialized = 'table'
)}}

-- Transform raw users data to bronze layer
SELECT
  user_id,
  user_name,
  email,
  company,
  plan_type,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'users') }}
