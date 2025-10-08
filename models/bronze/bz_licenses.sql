{{ config(
    materialized='table',
    pre_hook=[
      "{{ log_audit_start('bz_licenses') }}"
    ],
    post_hook=[
      "{{ log_audit_end('bz_licenses') }}"
    ]
) }}

-- Bronze layer transformation for licenses table
-- This model performs a 1:1 mapping from raw to bronze layer
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
)

SELECT
    -- Direct mapping of fields from source to target
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
