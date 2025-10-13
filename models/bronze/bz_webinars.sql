{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_webinars', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'STARTED' WHERE '{{ this.name }}' != 'bz_audit_log'",
    post_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_webinars', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'COMPLETED' WHERE '{{ this.name }}' != 'bz_audit_log'"
) }}

-- Bronze Webinars Table
-- Transforms raw webinars data with data quality checks and audit columns
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
    FROM {{ source('raw_zoom', 'webinars') }}
),

-- Data quality and cleansing layer
cleansed_data AS (
    SELECT 
        COALESCE(webinar_id, 'UNKNOWN') as webinar_id,
        COALESCE(host_id, 'UNKNOWN') as host_id,
        COALESCE(webinar_topic, 'UNKNOWN') as webinar_topic,
        start_time,
        end_time,
        COALESCE(registrants, 0) as registrants,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
    FROM source_data
)

SELECT * FROM cleansed_data
