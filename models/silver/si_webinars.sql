{{ config(materialized='table') }}

-- Silver Webinars Table
WITH bronze_webinars AS (
    SELECT *
    FROM {{ source('bronze', 'bz_webinars') }}
),

valid_users AS (
    SELECT DISTINCT user_id FROM {{ ref('si_users') }}
),

data_quality_checks AS (
    SELECT 
        bw.*,
        
        -- Completeness checks
        CASE WHEN webinar_id IS NULL THEN 1 ELSE 0 END as missing_webinar_id,
        CASE WHEN host_id IS NULL THEN 1 ELSE 0 END as missing_host_id,
        CASE WHEN webinar_topic IS NULL THEN 1 ELSE 0 END as missing_webinar_topic,
        CASE WHEN start_time IS NULL THEN 1 ELSE 0 END as missing_start_time,
        CASE WHEN end_time IS NULL THEN 1 ELSE 0 END as missing_end_time,
        
        -- Logical consistency
        CASE WHEN start_time IS NOT NULL AND end_time IS NOT NULL AND end_time <= start_time 
             THEN 1 ELSE 0 END as invalid_time_range,
        CASE WHEN registrants IS NOT NULL AND registrants < 0 THEN 1 ELSE 0 END as invalid_registrants,
        
        -- Referential integrity
        CASE WHEN vu.user_id IS NULL THEN 1 ELSE 0 END as invalid_host_ref,
        
        -- Calculate data quality score
        CASE 
            WHEN webinar_id IS NULL OR host_id IS NULL OR start_time IS NULL OR end_time IS NULL THEN 0.0
            WHEN end_time <= start_time THEN 0.2
            WHEN registrants < 0 THEN 0.4
            WHEN vu.user_id IS NULL THEN 0.6
            ELSE 1.0
        END as data_quality_score
    FROM bronze_webinars bw
    LEFT JOIN valid_users vu ON bw.host_id = vu.user_id
)

SELECT 
    webinar_id,
    host_id,
    TRIM(webinar_topic) as webinar_topic,
    start_time,
    end_time,
    CASE WHEN registrants >= 0 THEN registrants ELSE 0 END as registrants,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    data_quality_score,
    CASE 
        WHEN missing_webinar_id = 1 OR missing_host_id = 1 OR missing_start_time = 1 
             OR missing_end_time = 1 OR invalid_time_range = 1 OR invalid_host_ref = 1
        THEN 'error'
        ELSE 'active'
    END as record_status
FROM data_quality_checks
WHERE CASE 
        WHEN missing_webinar_id = 1 OR missing_host_id = 1 OR missing_start_time = 1 
             OR missing_end_time = 1 OR invalid_time_range = 1 OR invalid_host_ref = 1
        THEN 'error'
        ELSE 'active'
    END = 'active'
