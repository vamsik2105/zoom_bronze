{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_support_tickets' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_support_tickets', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_support_tickets')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_support_tickets' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_support_tickets', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_support_tickets')"
    ]
) }}

-- Source to Bronze transformation for Zoom support tickets
SELECT
    -- Primary fields
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'support_tickets') }}
