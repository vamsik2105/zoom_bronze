{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_feature_usage', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'STARTED' WHERE '{{ this.name }}' != 'bz_audit_log'",
    post_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_feature_usage', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'COMPLETED' WHERE '{{ this.name }}' != 'bz_audit_log'"
) }}

-- Bronze Feature Usage Table
-- Transforms raw feature usage data with data quality checks and audit columns
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
    FROM {{ source('raw_data', 'feature_usage') }}
),

-- Data quality and cleansing layer
cleansed_data AS (
    SELECT 
        COALESCE(usage_id, 'UNKNOWN') as usage_id,
        COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
        COALESCE(feature_name, 'UNKNOWN') as feature_name,
        COALESCE(usage_count, 0) as usage_count,
        usage_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
    FROM source_data
)

SELECT * FROM cleansed_data
