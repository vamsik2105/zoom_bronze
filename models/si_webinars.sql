-- Silver layer webinars table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'WEBINAR_001' as webinar_id,
    'USER_001' as host_id,
    'Product Launch Webinar' as webinar_topic,
    CURRENT_TIMESTAMP as start_time,
    DATEADD(hour, 2, CURRENT_TIMESTAMP) as end_time,
    150 as registrants,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'WEBINAR_002' as webinar_id,
    'USER_002' as host_id,
    'Training Session' as webinar_topic,
    DATEADD(day, 1, CURRENT_TIMESTAMP) as start_time,
    DATEADD(day, 1, DATEADD(hour, 1, CURRENT_TIMESTAMP)) as end_time,
    75 as registrants,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
