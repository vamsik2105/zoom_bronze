{{ config(
    materialized='table'
) }}

-- Webinars Silver Layer Transformation
WITH bronze_webinars AS (
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
    FROM BRONZE.bz_webinars
    WHERE load_timestamp IS NOT NULL
),

validated_webinars AS (
    SELECT *,
        CASE 
            WHEN webinar_id IS NULL OR TRIM(webinar_id) = '' THEN 'Missing webinar_id'
            WHEN host_id IS NULL OR TRIM(host_id) = '' THEN 'Missing host_id'
            WHEN webinar_topic IS NULL OR TRIM(webinar_topic) = '' THEN 'Missing webinar_topic'
            WHEN start_time IS NULL THEN 'Missing start_time'
            WHEN end_time IS NULL THEN 'Missing end_time'
            WHEN end_time <= start_time THEN 'Invalid time range'
            WHEN registrants IS NULL OR registrants < 0 THEN 'Invalid registrants'
            ELSE NULL
        END AS validation_error
    FROM bronze_webinars
),

transformed_webinars AS (
    SELECT 
        TRIM(webinar_id) as webinar_id,
        TRIM(host_id) as host_id,
        TRIM(webinar_topic) as webinar_topic,
        start_time,
        end_time,
        COALESCE(registrants, 0) as registrants,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 1.0
            ELSE 0.0
        END as data_quality_score,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status
    FROM validated_webinars
)

SELECT 
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    registrants,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM transformed_webinars
