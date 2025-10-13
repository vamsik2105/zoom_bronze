{{ config(materialized='table') }}

WITH bronze_webinars AS (
    SELECT * FROM {{ source('bronze', 'bz_webinars') }}
),

users_ref AS (
    SELECT user_id FROM {{ ref('si_users') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        bw.*,
        -- Quality score calculation
        CASE 
            WHEN bw.webinar_id IS NULL THEN 0
            WHEN bw.host_id IS NULL THEN 0.2
            WHEN bw.webinar_topic IS NULL THEN 0.3
            WHEN bw.start_time IS NULL OR bw.end_time IS NULL THEN 0.4
            WHEN bw.end_time <= bw.start_time THEN 0.5
            WHEN bw.registrants IS NULL OR bw.registrants < 0 THEN 0.6
            WHEN u.user_id IS NULL THEN 0.7  -- Host doesn't exist in users
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN bw.webinar_id IS NULL OR bw.host_id IS NULL OR bw.webinar_topic IS NULL THEN 'error'
            WHEN bw.start_time IS NULL OR bw.end_time IS NULL THEN 'error'
            WHEN bw.end_time <= bw.start_time THEN 'error'
            WHEN bw.registrants IS NULL OR bw.registrants < 0 THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_webinars bw
    LEFT JOIN users_ref u ON bw.host_id = u.user_id
),

-- Clean and transform data
cleaned_webinars AS (
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
    FROM dq_checks
    WHERE record_status = 'active'
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
FROM cleaned_webinars
