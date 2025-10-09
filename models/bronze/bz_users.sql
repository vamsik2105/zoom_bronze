{{ config(
    materialized='table'
) }}

SELECT 
    *,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'users') }}
