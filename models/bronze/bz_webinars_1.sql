{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_webinars', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_webinars transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_webinars', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_webinars transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for webinars
WITH source_webinars AS (
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

-- Data quality checks and transformations
cleaned_webinars AS (
    SELECT 
        COALESCE(webinar_id, 'UNKNOWN') as webinar_id,
        COALESCE(host_id, 'UNKNOWN') as host_id,
        COALESCE(webinar_topic, 'UNKNOWN') as webinar_topic,
        start_time,
        end_time,
        COALESCE(registrants, 0) as registrants,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_webinars
    WHERE webinar_id IS NOT NULL
)

SELECT * FROM cleaned_webinars
