{{ config(
    materialized='table',
    unique_key='webinar_id'
) }}

-- Silver Webinars Table Transformation
WITH bronze_webinars AS (
    SELECT *
    FROM {{ source('bronze', 'bz_webinars') }}
),

-- Data Quality Checks
data_quality_checks AS (
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
        -- Quality Score Calculation
        CASE 
            WHEN webinar_id IS NULL THEN 0
            WHEN host_id IS NULL THEN 0.2
            WHEN start_time IS NULL OR end_time IS NULL THEN 0.3
            WHEN end_time <= start_time THEN 0.4
            WHEN registrants IS NULL OR registrants < 0 THEN 0.5
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN webinar_id IS NULL OR host_id IS NULL THEN 'error'
            WHEN start_time IS NULL OR end_time IS NULL THEN 'error'
            WHEN end_time <= start_time THEN 'error'
            WHEN registrants IS NULL OR registrants < 0 THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_webinars
),

-- Clean and Transform Data
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
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'active'
)

SELECT * FROM transformed_webinars
