-- Bronze layer transformation for feature usage data
-- Maps raw feature usage data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_feature_usage') }}""",
    post_hook = """{{ log_table_process_end('bz_feature_usage', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    Usage_ID as usage_id,
    Meeting_ID as meeting_id,
    Feature_Name as feature_name,
    Usage_Count as usage_count,
    Usage_Date as usage_date,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'feature_usage') }}
