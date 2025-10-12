-- Silver layer webinars table with data quality checks and transformations
-- Transforms bronze webinars data with validation and cleansing

{{ config(
    materialized='table'
) }}

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
FROM {{ source('bronze', 'bz_webinars') }}
WHERE webinar_id IS NOT NULL
  AND host_id IS NOT NULL
