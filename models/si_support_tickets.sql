-- Silver layer support tickets table with data quality checks and transformations
-- Transforms bronze support tickets data with validation and cleansing

{{ config(
    materialized='table'
) }}

SELECT 
    ticket_id,
    user_id,
    CASE 
        WHEN UPPER(TRIM(ticket_type)) = 'AUDIO ISSUE' THEN 'Audio Issue'
        WHEN UPPER(TRIM(ticket_type)) = 'VIDEO ISSUE' THEN 'Video Issue'
        WHEN UPPER(TRIM(ticket_type)) = 'CONNECTIVITY' THEN 'Connectivity'
        WHEN UPPER(TRIM(ticket_type)) = 'BILLING INQUIRY' THEN 'Billing Inquiry'
        WHEN UPPER(TRIM(ticket_type)) = 'FEATURE REQUEST' THEN 'Feature Request'
        WHEN UPPER(TRIM(ticket_type)) = 'ACCOUNT ACCESS' THEN 'Account Access'
        ELSE ticket_type
    END as ticket_type,
    CASE 
        WHEN UPPER(TRIM(resolution_status)) = 'OPEN' THEN 'Open'
        WHEN UPPER(TRIM(resolution_status)) = 'IN PROGRESS' THEN 'In Progress'
        WHEN UPPER(TRIM(resolution_status)) = 'PENDING CUSTOMER' THEN 'Pending Customer'
        WHEN UPPER(TRIM(resolution_status)) = 'CLOSED' THEN 'Closed'
        WHEN UPPER(TRIM(resolution_status)) = 'RESOLVED' THEN 'Resolved'
        ELSE resolution_status
    END as resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    1.0 as data_quality_score,
    'active' as record_status
FROM {{ source('bronze', 'bz_support_tickets') }}
WHERE ticket_id IS NOT NULL
  AND user_id IS NOT NULL
