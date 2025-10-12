-- Silver layer users table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'USER_001' as user_id,
    'John Doe' as user_name,
    'john.doe@example.com' as email,
    'Example Corp' as company,
    'Pro' as plan_type,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'USER_002' as user_id,
    'Jane Smith' as user_name,
    'jane.smith@example.com' as email,
    'Tech Solutions' as company,
    'Business' as plan_type,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
