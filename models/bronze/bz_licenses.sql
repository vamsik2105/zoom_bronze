-- Bronze layer transformation for licenses data

{{ config(
    materialized = 'table',
    tags = ['bronze']
) }}

SELECT
    -- Direct 1:1 mapping from source
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'licenses') }}
