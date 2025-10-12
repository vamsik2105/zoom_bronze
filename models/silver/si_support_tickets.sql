{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'si_support_tickets', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED'",
    post_hook="UPDATE {{ ref('si_audit_log') }} SET status = 'COMPLETED', processing_time = 10 WHERE source_table = 'si_support_tickets' AND status = 'STARTED'"
) }}

-- Transform bronze support tickets data to silver layer with data quality checks
WITH bronze_support_tickets AS (
    SELECT *
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

-- Data quality validation
validated_support_tickets AS (
    SELECT 
        *,
        CASE 
            WHEN ticket_id IS NULL THEN 'NULL_TICKET_ID'
            WHEN user_id IS NULL THEN 'NULL_USER_ID'
            WHEN ticket_type IS NULL THEN 'NULL_TICKET_TYPE'
            WHEN ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 'INVALID_TICKET_TYPE'
            WHEN resolution_status IS NULL THEN 'NULL_RESOLUTION_STATUS'
            WHEN resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 'INVALID_RESOLUTION_STATUS'
            WHEN open_date IS NULL THEN 'NULL_OPEN_DATE'
            ELSE 'VALID'
        END AS validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN ticket_id IS NOT NULL 
                AND user_id IS NOT NULL 
                AND ticket_type IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access')
                AND resolution_status IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved')
                AND open_date IS NOT NULL
            THEN 1.0
            WHEN ticket_id IS NOT NULL AND user_id IS NOT NULL
            THEN 0.75
            WHEN ticket_id IS NOT NULL
            THEN 0.5
            ELSE 0.0
        END AS data_quality_score
    FROM bronze_support_tickets
),

-- Clean and transform valid records
clean_support_tickets AS (
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
        END AS ticket_type,
        CASE 
            WHEN UPPER(resolution_status) = 'OPEN' THEN 'Open'
            WHEN UPPER(resolution_status) = 'IN PROGRESS' THEN 'In Progress'
            WHEN UPPER(resolution_status) = 'PENDING CUSTOMER' THEN 'Pending Customer'
            WHEN UPPER(resolution_status) = 'CLOSED' THEN 'Closed'
            WHEN UPPER(resolution_status) = 'RESOLVED' THEN 'Resolved'
            ELSE resolution_status
        END AS resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_support_tickets
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_support_tickets
