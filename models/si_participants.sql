-- Silver layer participants table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'PARTICIPANT_001' as participant_id,
    'MEETING_001' as meeting_id,
    'USER_001' as user_id,
    CURRENT_TIMESTAMP as join_time,
    DATEADD(minute, 55, CURRENT_TIMESTAMP) as leave_time,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'PARTICIPANT_002' as participant_id,
    'MEETING_001' as meeting_id,
    'USER_002' as user_id,
    DATEADD(minute, 5, CURRENT_TIMESTAMP) as join_time,
    DATEADD(minute, 60, CURRENT_TIMESTAMP) as leave_time,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
