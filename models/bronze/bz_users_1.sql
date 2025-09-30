{{config(
    materialized='table'
)}}

-- Extract and transform users data from raw to bronze
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
