-- Bronze layer transformation for users data

{{ config(
    materialized = 'table'
) }}

SELECT
    -- Map source columns to target columns
    User_ID as user_id,
    User_Name as user_name,
    Email as email,
    Company as company,
    Plan_Type as plan_type,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'users') }}
