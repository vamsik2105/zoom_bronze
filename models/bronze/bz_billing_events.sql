-- Bronze layer transformation for billing events data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "{{ log_audit_start('bz_billing_events') }}",
    post_hook = "{{ log_audit_end('bz_billing_events', True) }}"
) }}

SELECT
    -- Direct 1:1 mapping from source
    event_id,
    user_id,
    event_type,
    amount,
    event_date,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'billing_events') }}
