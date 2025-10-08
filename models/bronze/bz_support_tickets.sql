{{ config(
    materialized='table',
    pre_hook=[
      "{{ log_audit_start('bz_support_tickets') }}"
    ],
    post_hook=[
      "{{ log_audit_end('bz_support_tickets') }}"
    ]
) }}

-- Bronze layer transformation for support_tickets table
-- This model performs a 1:1 mapping from raw to bronze layer
WITH source_data AS (
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'support_tickets') }}
)

SELECT
    -- Direct mapping of fields from source to target
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
