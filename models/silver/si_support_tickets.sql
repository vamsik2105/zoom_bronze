{{ config(
    materialized='table'
) }}

-- Support Tickets Silver Layer Transformation
WITH bronze_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM BRONZE.bz_support_tickets
    WHERE load_timestamp IS NOT NULL
),

validated_support_tickets AS (
    SELECT *,
        CASE 
            WHEN ticket_id IS NULL OR TRIM(ticket_id) = '' THEN 'Missing ticket_id'
            WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 'Missing user_id'
            WHEN ticket_type IS NULL OR TRIM(ticket_type) = '' THEN 'Missing ticket_type'
            WHEN UPPER(TRIM(ticket_type)) NOT IN ('AUDIO ISSUE', 'VIDEO ISSUE', 'CONNECTIVITY', 'BILLING INQUIRY', 'FEATURE REQUEST', 'ACCOUNT ACCESS') THEN 'Invalid ticket_type'
            WHEN resolution_status IS NULL OR TRIM(resolution_status) = '' THEN 'Missing resolution_status'
            WHEN UPPER(TRIM(resolution_status)) NOT IN ('OPEN', 'IN PROGRESS', 'PENDING CUSTOMER', 'CLOSED', 'RESOLVED') THEN 'Invalid resolution_status'
            WHEN open_date IS NULL THEN 'Missing open_date'
            ELSE NULL
        END AS validation_error
    FROM bronze_support_tickets
),

transformed_support_tickets AS (
    SELECT 
        TRIM(ticket_id) as ticket_id,
        TRIM(user_id) as user_id,
        CASE 
            WHEN UPPER(TRIM(ticket_type)) = 'AUDIO ISSUE' THEN 'Audio Issue'
            WHEN UPPER(TRIM(ticket_type)) = 'VIDEO ISSUE' THEN 'Video Issue'
            WHEN UPPER(TRIM(ticket_type)) = 'CONNECTIVITY' THEN 'Connectivity'
            WHEN UPPER(TRIM(ticket_type)) = 'BILLING INQUIRY' THEN 'Billing Inquiry'
            WHEN UPPER(TRIM(ticket_type)) = 'FEATURE REQUEST' THEN 'Feature Request'
            WHEN UPPER(TRIM(ticket_type)) = 'ACCOUNT ACCESS' THEN 'Account Access'
            ELSE 'Other'
        END as ticket_type,
        CASE 
            WHEN UPPER(TRIM(resolution_status)) = 'OPEN' THEN 'Open'
            WHEN UPPER(TRIM(resolution_status)) = 'IN PROGRESS' THEN 'In Progress'
            WHEN UPPER(TRIM(resolution_status)) = 'PENDING CUSTOMER' THEN 'Pending Customer'
            WHEN UPPER(TRIM(resolution_status)) = 'CLOSED' THEN 'Closed'
            WHEN UPPER(TRIM(resolution_status)) = 'RESOLVED' THEN 'Resolved'
            ELSE 'Unknown'
        END as resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 1.0
            ELSE 0.0
        END as data_quality_score,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status
    FROM validated_support_tickets
)

SELECT 
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM transformed_support_tickets
