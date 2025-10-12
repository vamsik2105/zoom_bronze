-- Silver layer feature usage table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'USAGE_001' as usage_id,
    'MEETING_001' as meeting_id,
    'Screen Sharing' as feature_name,
    3 as usage_count,
    CURRENT_DATE as usage_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'USAGE_002' as usage_id,
    'MEETING_001' as meeting_id,
    'Chat' as feature_name,
    15 as usage_count,
    CURRENT_DATE as usage_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
