{{ config(
    materialized='table'
) }}

-- Bronze Licenses Table
-- Transforms raw licenses data with data quality checks and audit columns
WITH source_data AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw_data', 'licenses') }}
),

-- Data quality and cleansing layer
cleansed_data AS (
    SELECT 
        COALESCE(license_id, 'UNKNOWN') as license_id,
        COALESCE(license_type, 'UNKNOWN') as license_type,
        COALESCE(assigned_to_user_id, 'UNKNOWN') as assigned_to_user_id,
        start_date,
        end_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
    FROM source_data
)

SELECT * FROM cleansed_data
