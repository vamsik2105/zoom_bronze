{{ config(
    materialized='table'
) }}

WITH bronze_webinars AS (
    SELECT *
    FROM BRONZE.bz_webinars
),

-- Data Quality Validations
validated_webinars AS (
    SELECT *,
        CASE 
            WHEN webinar_id IS NULL THEN 'Missing webinar_id'
            WHEN host_id IS NULL THEN 'Missing host_id'
            WHEN webinar_topic IS NULL THEN 'Missing webinar_topic'
            WHEN start_time IS NULL THEN 'Missing start_time'
            WHEN end_time IS NULL THEN 'Missing end_time'
            WHEN end_time <= start_time THEN 'Invalid time range'
            WHEN registrants IS NULL OR registrants < 0 THEN 'Invalid registrants'
            ELSE NULL
        END AS validation_error
    FROM bronze_webinars
),

-- Clean and Transform Data
transformed_webinars AS (
    SELECT 
        webinar_id,
        host_id,
        TRIM(webinar_topic) as webinar_topic,
        start_time,
        end_time,
        registrants,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
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
    {{ calculate_data_quality_score('transformed_webinars') }} as data_quality_score,
    record_status
FROM transformed_webinars
WHERE validation_error IS NULL

UNION ALL

-- Error Records for Audit
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
    0.0 as data_quality_score,
    'error' as record_status
FROM transformed_webinars
WHERE validation_error IS NOT NULL
