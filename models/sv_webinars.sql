-- =====================================================
-- SILVER WEBINARS MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

WITH bronze_webinars AS (
    SELECT *
    FROM {{ source('bronze', 'bz_webinars') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN webinar_id IS NULL THEN 0 ELSE 1 END as webinar_id_check,
        CASE WHEN host_id IS NULL THEN 0 ELSE 1 END as host_id_check,
        CASE WHEN webinar_topic IS NULL THEN 0 ELSE 1 END as webinar_topic_check,
        CASE WHEN start_time IS NULL THEN 0 ELSE 1 END as start_time_check,
        CASE WHEN end_time IS NULL THEN 0 ELSE 1 END as end_time_check,
        CASE WHEN registrants IS NULL THEN 0 ELSE 1 END as registrants_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Logic checks
        CASE WHEN end_time > start_time THEN 1 ELSE 0 END as time_logic_check,
        CASE WHEN registrants >= 0 THEN 1 ELSE 0 END as registrants_range_check
    FROM bronze_webinars
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (webinar_id_check + host_id_check + webinar_topic_check + start_time_check + 
             end_time_check + registrants_check + source_system_check + time_logic_check + registrants_range_check) / 9.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN webinar_id IS NULL OR host_id IS NULL OR webinar_topic IS NULL OR start_time IS NULL OR end_time IS NULL OR registrants IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN end_time <= start_time THEN 'ERROR'
            WHEN registrants < 0 THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_webinars AS (
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
        record_status
    FROM quality_scored
    WHERE record_status = 'ACTIVE'
)

SELECT * FROM final_webinars
