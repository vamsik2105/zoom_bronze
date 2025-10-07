-- Bronze layer transformation for support tickets data

{{ config(
    materialized = 'table',
    tags = ['bronze']
) }}

SELECT
    -- Direct 1:1 mapping from source
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'support_tickets') }}
