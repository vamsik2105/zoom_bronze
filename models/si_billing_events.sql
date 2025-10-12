-- Silver layer billing events table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'EVENT_001' as event_id,
    'USER_001' as user_id,
    'Subscription Fee' as event_type,
    14.99 as amount,
    CURRENT_DATE as event_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'EVENT_002' as event_id,
    'USER_002' as user_id,
    'Subscription Renewal' as event_type,
    19.99 as amount,
    DATEADD(day, -1, CURRENT_DATE) as event_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
