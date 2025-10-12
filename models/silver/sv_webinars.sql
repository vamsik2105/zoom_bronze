{{
  config(
    materialized='table'
  )
}}

-- Transform bronze webinars to silver layer with data quality checks
WITH bronze_webinars AS (
    SELECT *
    FROM {{ source('bronze', 'bz_webinars') }}
),

-- Data Quality Validation
validated_webinars AS (
    SELECT 
        *,
        -- Data Quality Checks
        CASE 
            WHEN webinar_id IS NULL OR TRIM(webinar_id) = '' THEN 'INVALID_WEBINAR_ID'
            WHEN host_id IS NULL OR TRIM(host_id) = '' THEN 'INVALID_HOST_ID'
            WHEN webinar_topic IS NULL OR TRIM(webinar_topic) = '' THEN 'INVALID_WEBINAR_TOPIC'
            WHEN start_time IS NULL THEN 'INVALID_START_TIME'
            WHEN end_time IS NULL THEN 'INVALID_END_TIME'
            WHEN end_time <= start_time THEN 'INVALID_TIME_RANGE'
            WHEN registrants IS NULL OR registrants < 0 THEN 'INVALID_REGISTRANTS'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'INVALID_SOURCE_SYSTEM'
            ELSE 'VALID'
        END as validation_status
    FROM bronze_webinars
),

-- Valid Records for Silver Layer
valid_records AS (
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
        1.0 as data_quality_score,
        'active' as record_status
    FROM validated_webinars
    WHERE validation_status = 'VALID'
)

SELECT * FROM valid_records
