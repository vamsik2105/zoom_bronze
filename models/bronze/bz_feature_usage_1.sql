{{ config(
    materialized='table'
) }}

-- Bronze layer transformation for feature usage
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
),

cleaned_data AS (
    SELECT 
        -- Direct 1-to-1 mapping from raw to bronze
        usage_id,
        meeting_id,
        feature_name,
        usage_count,
        usage_date,
        -- Metadata columns with current timestamp
        CURRENT_TIMESTAMP as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_data
    WHERE usage_id IS NOT NULL -- Basic data quality check
)

SELECT * FROM cleaned_data
