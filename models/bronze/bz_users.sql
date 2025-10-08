{{ config(
    materialized='table'
) }}

-- Bronze layer transformation for users table
-- This model performs a 1:1 mapping from raw to bronze layer
WITH source_data AS (
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
)

SELECT
    -- Direct mapping of fields from source to target
    user_id,
    user_name,
    email,
    company,
    plan_type,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
