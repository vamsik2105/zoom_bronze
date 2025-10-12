{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'si_webinars', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED'",
    post_hook="UPDATE {{ ref('si_audit_log') }} SET status = 'COMPLETED', processing_time = 10 WHERE source_table = 'si_webinars' AND status = 'STARTED'"
) }}

-- Transform bronze webinars data to silver layer with data quality checks
WITH bronze_webinars AS (
    SELECT *
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
        END AS validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN webinar_id IS NOT NULL 
                AND host_id IS NOT NULL 
                AND webinar_topic IS NOT NULL
                AND start_time IS NOT NULL
                AND end_time IS NOT NULL
                AND end_time > start_time
                AND registrants >= 0
            THEN 1.0
            WHEN webinar_id IS NOT NULL AND host_id IS NOT NULL
            THEN 0.75
            WHEN webinar_id IS NOT NULL
            THEN 0.5
            ELSE 0.0
        END AS data_quality_score
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_webinars
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_webinars
