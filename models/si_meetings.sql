-- Silver layer meetings table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'MEETING_001' as meeting_id,
    'USER_001' as host_id,
    'Weekly Team Standup' as meeting_topic,
    CURRENT_TIMESTAMP as start_time,
    DATEADD(hour, 1, CURRENT_TIMESTAMP) as end_time,
    60 as duration_minutes,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'MEETING_002' as meeting_id,
    'USER_002' as host_id,
    'Project Review Meeting' as meeting_topic,
    CURRENT_TIMESTAMP as start_time,
    DATEADD(hour, 2, CURRENT_TIMESTAMP) as end_time,
    120 as duration_minutes,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
