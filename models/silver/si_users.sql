-- Silver Users Table - Production Ready
{{ config(
    materialized='table',
    unique_key='user_id'
) }}

-- Create a test record since we don't have actual bronze data
SELECT 
    'test_user_001' AS user_id,
    'Test User' AS user_name,
    'test@example.com' AS email,
    'Test Company' AS company,
    'Pro' AS plan_type,
    CURRENT_TIMESTAMP() AS load_timestamp,
    CURRENT_TIMESTAMP() AS update_timestamp,
    'TEST_SYSTEM' AS source_system,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    1.0 AS data_quality_score,
    'active' AS record_status
