{{ config(materialized='table') }}
WITH source_data AS (SELECT user_id, user_name, email, company, plan_type FROM {{ source('raw_data', 'users') }} WHERE user_id IS NOT NULL)
SELECT user_id, user_name, email, company, plan_type, CURRENT_TIMESTAMP() as load_timestamp, CURRENT_TIMESTAMP() as update_timestamp, 'ZOOM_PLATFORM' as source_system FROM source_data
