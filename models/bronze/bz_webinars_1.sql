{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, status, message, created_at) SELECT 'bz_webinars', CURRENT_TIMESTAMP, 'STARTED', 'Processing bz_webinars transformation', CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, status, message, created_at) SELECT 'bz_webinars', CURRENT_TIMESTAMP, 'SUCCESS', 'Completed bz_webinars transformation', CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for webinars
WITH source_data AS (
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'webinars') }}
),

cleaned_data AS (
    SELECT 
        -- Direct 1-to-1 mapping from raw to bronze
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        -- Metadata columns with current timestamp
        CURRENT_TIMESTAMP as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_data
    WHERE webinar_id IS NOT NULL -- Basic data quality check
)

SELECT * FROM cleaned_data
