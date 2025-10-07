-- Bronze layer transformation for users data

{{ config(
    materialized = 'table'
) }}

SELECT
    'test_id' as user_id,
    'test_name' as user_name,
    'test@example.com' as email,
    'Test Company' as company,
    'Basic' as plan_type,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
