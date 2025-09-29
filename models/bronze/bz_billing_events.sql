{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_billing_events' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_billing_events', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_billing_events')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_billing_events' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_billing_events', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_billing_events')"
    ]
) }}

-- Source to Bronze transformation for Zoom billing events
SELECT
    -- Primary fields
    event_id,
    user_id,
    event_type,
    amount,
    event_date,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'billing_events') }}
