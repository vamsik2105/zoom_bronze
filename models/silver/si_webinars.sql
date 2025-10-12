{{
  config(
    materialized='table'
  )
}}

-- Transform bronze webinars to silver webinars with data quality checks
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

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN webinar_id IS NULL OR webinar_id = '' THEN 'INVALID_WEBINAR_ID'
            WHEN host_id IS NULL OR host_id = '' THEN 'MISSING_HOST_ID'
            WHEN webinar_topic IS NULL OR webinar_topic = '' THEN 'MISSING_WEBINAR_TOPIC'
            WHEN start_time IS NULL THEN 'MISSING_START_TIME'
            WHEN end_time IS NULL THEN 'MISSING_END_TIME'
            WHEN end_time <= start_time THEN 'INVALID_TIME_RANGE'
            WHEN registrants IS NULL OR registrants < 0 THEN 'INVALID_REGISTRANTS'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN webinar_id IS NULL OR webinar_id = '' THEN 0.0
            WHEN host_id IS NULL OR host_id = '' THEN 0.3
            WHEN webinar_topic IS NULL OR webinar_topic = '' THEN 0.5
            WHEN end_time <= start_time THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_webinars
),

cleaned_webinars AS (
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_webinars
