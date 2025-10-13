{{ config(
    materialized='table'
) }}

-- Simple transformation for feature usage table
SELECT 
    'USAGE-001' as usage_id,
    'MEET-001' as meeting_id,
    'Screen Sharing' as feature_name,
    5 as usage_count,
    CURRENT_DATE() as usage_date,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'SYSTEM' as source_system,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    1.0 as data_quality_score,
    'active' as record_status
WHERE FALSE -- This ensures no initial record is created
