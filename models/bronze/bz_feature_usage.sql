{{ config(
    materialized='table',
    pre_hook=[
      "{{ log_audit_start('bz_feature_usage') }}"
    ],
    post_hook=[
      "{{ log_audit_end('bz_feature_usage') }}"
    ]
) }}

-- Bronze layer transformation for feature_usage table
-- This model performs a 1:1 mapping from raw to bronze layer
WITH source_data AS (
    SELECT 
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'feature_usage') }}
)

SELECT
    -- Direct mapping of fields from source to target
    usage_id,
    meeting_id,
    feature_name,
    usage_count,
    usage_date,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
