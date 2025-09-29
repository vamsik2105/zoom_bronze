{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (model_name, process_timestamp, status, message) VALUES ('bz_users', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_users')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (model_name, process_timestamp, status, message) VALUES ('bz_users', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_users')"
    ]
) }}

-- Source to Bronze transformation for Zoom users
SELECT
    -- Primary fields
    user_id,
    user_name,
    email,
    company,
    plan_type,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'users') }}
