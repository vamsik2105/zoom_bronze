-- Bronze layer transformation for feature usage data

{{ config(
    materialized = 'table',
    tags = ['bronze']
) }}

SELECT
    -- Direct 1:1 mapping from source
    usage_id,
    meeting_id,
    feature_name,
    usage_count,
    usage_date,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'feature_usage') }}
