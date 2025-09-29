{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_feature_usage' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_feature_usage', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_feature_usage')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_feature_usage' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_feature_usage', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_feature_usage')"
    ]
) }}

-- Source to Bronze transformation for Zoom feature usage
SELECT
    -- Primary fields
    usage_id,
    meeting_id,
    feature_name,
    usage_count,
    usage_date,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'feature_usage') }}
