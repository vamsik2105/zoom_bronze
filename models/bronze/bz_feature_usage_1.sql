{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_feature_usage', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_feature_usage transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_feature_usage', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_feature_usage transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for feature usage
WITH source_feature_usage AS (
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
),

-- Data quality checks and transformations
cleaned_feature_usage AS (
    SELECT 
        COALESCE(usage_id, 'UNKNOWN') as usage_id,
        COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
        COALESCE(feature_name, 'UNKNOWN') as feature_name,
        COALESCE(usage_count, 0) as usage_count,
        usage_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_feature_usage
    WHERE usage_id IS NOT NULL
)

SELECT * FROM cleaned_feature_usage
