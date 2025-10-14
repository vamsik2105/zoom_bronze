{{ config(
    materialized='table',
    unique_key='webinar_id'
) }}

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

-- Data quality validation
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
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_webinars
),

-- Clean and transform valid records
clean_webinars AS (
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
        CASE 
            WHEN webinar_id IS NOT NULL AND host_id IS NOT NULL 
                 AND webinar_topic IS NOT NULL AND start_time IS NOT NULL 
                 AND end_time IS NOT NULL AND end_time > start_time 
                 AND registrants >= 0 THEN 1.0
            ELSE 0.5
        END AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_webinars
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_webinars
