{{ config(
    materialized='table',
    pre_hook=[
      "{{ log_audit_start('bz_billing_events') }}"
    ],
    post_hook=[
      "{{ log_audit_end('bz_billing_events') }}"
    ]
) }}

-- Bronze layer transformation for billing_events table
-- This model performs a 1:1 mapping from raw to bronze layer
WITH source_data AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'billing_events') }}
)

SELECT
    -- Direct mapping of fields from source to target
    event_id,
    user_id,
    event_type,
    amount,
    event_date,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
