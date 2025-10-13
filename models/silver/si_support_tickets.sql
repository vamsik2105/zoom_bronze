{{ config(
    materialized='table'
) }}

WITH bronze_support_tickets AS (
    SELECT *
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

-- Data Quality Validations
validated_support_tickets AS (
    SELECT *,
        CASE 
            WHEN ticket_id IS NULL THEN 'Missing ticket_id'
            WHEN user_id IS NULL THEN 'Missing user_id'
            WHEN ticket_type IS NULL THEN 'Missing ticket_type'
            WHEN ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 'Invalid ticket_type'
            WHEN resolution_status IS NULL THEN 'Missing resolution_status'
            WHEN resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 'Invalid resolution_status'
            WHEN open_date IS NULL THEN 'Missing open_date'
            ELSE NULL
        END AS validation_error
    FROM bronze_support_tickets
),

-- Clean and Transform Data
transformed_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN UPPER(ticket_type) = 'AUDIO ISSUE' THEN 'Audio Issue'
            WHEN UPPER(ticket_type) = 'VIDEO ISSUE' THEN 'Video Issue'
            WHEN UPPER(ticket_type) = 'CONNECTIVITY' THEN 'Connectivity'
            WHEN UPPER(ticket_type) = 'BILLING INQUIRY' THEN 'Billing Inquiry'
            WHEN UPPER(ticket_type) = 'FEATURE REQUEST' THEN 'Feature Request'
            WHEN UPPER(ticket_type) = 'ACCOUNT ACCESS' THEN 'Account Access'
            ELSE ticket_type
        END as ticket_type,
        CASE 
            WHEN UPPER(resolution_status) = 'OPEN' THEN 'Open'
            WHEN UPPER(resolution_status) = 'IN PROGRESS' THEN 'In Progress'
            WHEN UPPER(resolution_status) = 'PENDING CUSTOMER' THEN 'Pending Customer'
            WHEN UPPER(resolution_status) = 'CLOSED' THEN 'Closed'
            WHEN UPPER(resolution_status) = 'RESOLVED' THEN 'Resolved'
            ELSE resolution_status
        END as resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
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
    {{ calculate_data_quality_score('transformed_support_tickets') }} as data_quality_score,
    record_status
FROM transformed_support_tickets
WHERE validation_error IS NULL

UNION ALL

-- Error Records for Audit
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
    0.0 as data_quality_score,
    'error' as record_status
FROM transformed_support_tickets
WHERE validation_error IS NOT NULL
