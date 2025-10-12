-- Silver Webinars Table - Cleaned and validated webinar data

{{ config(
    materialized='table',
    unique_key='webinar_id'
) }}

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
    FROM {{ source('bronze', 'bz_webinars') }}
),

validated_webinars AS (
    SELECT 
        *,
        CASE 
            WHEN webinar_id IS NULL THEN 'NULL_WEBINAR_ID'
            WHEN host_id IS NULL THEN 'NULL_HOST_ID'
            WHEN webinar_topic IS NULL THEN 'NULL_WEBINAR_TOPIC'
            WHEN start_time IS NULL THEN 'NULL_START_TIME'
            WHEN end_time IS NULL THEN 'NULL_END_TIME'
            WHEN end_time <= start_time THEN 'INVALID_TIME_RANGE'
            WHEN registrants IS NULL OR registrants < 0 THEN 'INVALID_REGISTRANTS'
            WHEN source_system IS NULL THEN 'NULL_SOURCE_SYSTEM'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_webinars
),

transformed_webinars AS (
    SELECT 
        webinar_id,
        host_id,
        TRIM(webinar_topic) AS webinar_topic,
        start_time,
        end_time,
        registrants,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        {{ calculate_data_quality_score('si_webinars', 'webinar_id') }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status,
        validation_status
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
WHERE validation_status = 'VALID'

UNION ALL

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
    0.0 AS data_quality_score,
    'error' AS record_status
FROM transformed_webinars
WHERE validation_status != 'VALID'
