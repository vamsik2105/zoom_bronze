{{ config(
    materialized='table',
    unique_key='ticket_id'
) }}

-- Silver Support Tickets Table Transformation
WITH bronze_support_tickets AS (
    SELECT *
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Quality Score Calculation
        CASE 
            WHEN ticket_id IS NULL THEN 0
            WHEN user_id IS NULL THEN 0.2
            WHEN open_date IS NULL THEN 0.3
            WHEN ticket_type NOT IN ('Audio Issue','Video Issue','Connectivity','Billing Inquiry','Feature Request','Account Access') THEN 0.6
            WHEN resolution_status NOT IN ('Open','In Progress','Pending Customer','Closed','Resolved') THEN 0.7
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN ticket_id IS NULL OR user_id IS NULL OR open_date IS NULL THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_support_tickets
),

-- Clean and Transform Data
transformed_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(ticket_type)) IN ('AUDIO ISSUE','VIDEO ISSUE','CONNECTIVITY','BILLING INQUIRY','FEATURE REQUEST','ACCOUNT ACCESS')
            THEN UPPER(TRIM(ticket_type))
            ELSE 'OTHER'
        END AS ticket_type,
        CASE 
            WHEN UPPER(TRIM(resolution_status)) IN ('OPEN','IN PROGRESS','PENDING CUSTOMER','CLOSED','RESOLVED')
            THEN UPPER(TRIM(resolution_status))
            ELSE 'UNKNOWN'
        END AS resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'active'
)

SELECT * FROM transformed_support_tickets
