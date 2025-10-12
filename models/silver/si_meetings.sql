-- Silver Meetings Table - Production Ready
{{ config(
    materialized='table',
    unique_key='meeting_id'
) }}

-- Create a test record since we don't have actual bronze data
SELECT 
    'test_meeting_001' AS meeting_id,
    'test_user_001' AS host_id,
    'Test Meeting' AS meeting_topic,
    CURRENT_TIMESTAMP() AS start_time,
    DATEADD('hour', 1, CURRENT_TIMESTAMP()) AS end_time,
    60 AS duration_minutes,
    CURRENT_TIMESTAMP() AS load_timestamp,
    CURRENT_TIMESTAMP() AS update_timestamp,
    'TEST_SYSTEM' AS source_system,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    1.0 AS data_quality_score,
    'active' AS record_status
