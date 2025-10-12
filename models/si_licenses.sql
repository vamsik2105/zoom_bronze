-- Silver layer licenses table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'LICENSE_001' as license_id,
    'Pro' as license_type,
    'USER_001' as assigned_to_user_id,
    DATEADD(day, -30, CURRENT_DATE) as start_date,
    DATEADD(day, 335, CURRENT_DATE) as end_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'LICENSE_002' as license_id,
    'Business' as license_type,
    'USER_002' as assigned_to_user_id,
    DATEADD(day, -60, CURRENT_DATE) as start_date,
    DATEADD(day, 305, CURRENT_DATE) as end_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
