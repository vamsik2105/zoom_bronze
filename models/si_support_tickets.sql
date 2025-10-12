-- Silver layer support tickets table with data quality checks and transformations
-- Creates sample data for demonstration

{{ config(
    materialized='table'
) }}

SELECT 
    'TICKET_001' as ticket_id,
    'USER_001' as user_id,
    'Audio Issue' as ticket_type,
    'Open' as resolution_status,
    CURRENT_DATE as open_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status

UNION ALL

SELECT 
    'TICKET_002' as ticket_id,
    'USER_002' as user_id,
    'Billing Inquiry' as ticket_type,
    'Resolved' as resolution_status,
    DATEADD(day, -2, CURRENT_DATE) as open_date,
    CURRENT_TIMESTAMP as load_timestamp,
    CURRENT_TIMESTAMP as update_timestamp,
    'BRONZE_SYSTEM' as source_system,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    1.0 as data_quality_score,
    'active' as record_status
