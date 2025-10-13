{{ config(
    materialized='table'
) }}

-- Bronze Users Table
-- Transforms raw users data with data quality checks and audit columns
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
    FROM {{ source('raw_data', 'users') }}
),

-- Data quality and cleansing layer
cleansed_data AS (
    SELECT 
        COALESCE(user_id, 'UNKNOWN') as user_id,
        COALESCE(user_name, 'UNKNOWN') as user_name,
        COALESCE(email, 'UNKNOWN') as email,
        COALESCE(company, 'UNKNOWN') as company,
        COALESCE(plan_type, 'UNKNOWN') as plan_type,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
    FROM source_data
)

SELECT * FROM cleansed_data
