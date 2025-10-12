{{
  config(
    materialized='table'
  )
}}

-- Transform bronze support tickets to silver support tickets with data quality checks
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
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN ticket_id IS NULL OR ticket_id = '' THEN 'INVALID_TICKET_ID'
            WHEN user_id IS NULL OR user_id = '' THEN 'MISSING_USER_ID'
            WHEN ticket_type IS NULL OR ticket_type = '' THEN 'MISSING_TICKET_TYPE'
            WHEN ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 'INVALID_TICKET_TYPE'
            WHEN resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 'INVALID_RESOLUTION_STATUS'
            WHEN open_date IS NULL THEN 'MISSING_OPEN_DATE'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN ticket_id IS NULL OR ticket_id = '' THEN 0.0
            WHEN user_id IS NULL OR user_id = '' THEN 0.3
            WHEN ticket_type IS NULL OR ticket_type = '' THEN 0.5
            WHEN open_date IS NULL THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_support_tickets
),

cleaned_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN UPPER(ticket_type) LIKE '%AUDIO%' THEN 'Audio Issue'
            WHEN UPPER(ticket_type) LIKE '%VIDEO%' THEN 'Video Issue'
            WHEN UPPER(ticket_type) LIKE '%CONNECT%' THEN 'Connectivity'
            WHEN UPPER(ticket_type) LIKE '%BILLING%' THEN 'Billing Inquiry'
            WHEN UPPER(ticket_type) LIKE '%FEATURE%' THEN 'Feature Request'
            WHEN UPPER(ticket_type) LIKE '%ACCOUNT%' THEN 'Account Access'
            ELSE ticket_type
        END as ticket_type,
        CASE 
            WHEN UPPER(resolution_status) = 'OPEN' THEN 'Open'
            WHEN UPPER(resolution_status) LIKE '%PROGRESS%' THEN 'In Progress'
            WHEN UPPER(resolution_status) LIKE '%PENDING%' THEN 'Pending Customer'
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
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_support_tickets
