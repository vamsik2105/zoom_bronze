{{ config(
    materialized='table'
) }}

-- Bronze layer transformation for licenses
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
    FROM {{ source('raw', 'licenses') }}
),

cleaned_data AS (
    SELECT 
        -- Direct 1-to-1 mapping from raw to bronze
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        -- Metadata columns with current timestamp
        CURRENT_TIMESTAMP as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_data
    WHERE license_id IS NOT NULL -- Basic data quality check
)

SELECT * FROM cleaned_data
