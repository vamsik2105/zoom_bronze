-- Bronze layer transformation for feature usage data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "{{ log_audit_start('bz_feature_usage') }}",
    post_hook = "{{ log_audit_end('bz_feature_usage', True) }}"
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
