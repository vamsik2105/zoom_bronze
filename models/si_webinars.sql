-- Silver layer webinars table with data quality checks and transformations
-- Transforms bronze webinars data with validation and cleansing

{{ config(
    materialized='table'
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

-- Data quality validation
validated_webinars AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN webinar_id IS NULL THEN 1 ELSE 0 END as null_webinar_id,
        CASE WHEN host_id IS NULL THEN 1 ELSE 0 END as null_host_id,
        CASE WHEN start_time IS NULL THEN 1 ELSE 0 END as null_start_time,
        
        -- Logical validation
        CASE WHEN end_time IS NOT NULL AND start_time IS NOT NULL AND end_time <= start_time 
             THEN 1 ELSE 0 END as invalid_time_range,
        CASE WHEN registrants IS NOT NULL AND registrants < 0 
             THEN 1 ELSE 0 END as invalid_registrants
    FROM bronze_webinars
),

-- Clean and transform data
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
        
        -- Data quality flags
        null_webinar_id + null_host_id + null_start_time + invalid_time_range + invalid_registrants as error_count,
        
        -- Record status
        CASE 
            WHEN null_webinar_id = 1 OR null_host_id = 1 OR null_start_time = 1 OR invalid_time_range = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_webinars
),

-- Calculate data quality score
final_webinars AS (
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
        
        -- Data quality score calculation
        CASE 
            WHEN error_count = 0 THEN 1.0
            WHEN error_count = 1 THEN 0.8
            WHEN error_count = 2 THEN 0.6
            WHEN error_count = 3 THEN 0.4
            WHEN error_count = 4 THEN 0.2
            ELSE 0.0
        END as data_quality_score,
        
        record_status
    FROM cleaned_webinars
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_webinars
