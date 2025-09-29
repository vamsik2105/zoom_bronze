{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_webinars' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_webinars', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_webinars')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_webinars' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_webinars', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_webinars')"
    ]
) }}

-- Source to Bronze transformation for Zoom webinars
SELECT
    -- Primary fields
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    registrants,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'webinars') }}
