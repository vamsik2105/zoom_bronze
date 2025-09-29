{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_licenses' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_licenses', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_licenses')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_licenses' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_licenses', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_licenses')"
    ]
) }}

-- Source to Bronze transformation for Zoom licenses
SELECT
    -- Primary fields
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'licenses') }}
