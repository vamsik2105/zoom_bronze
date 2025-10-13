{{ config(materialized='table') }}

WITH bronze_support_tickets AS (
    SELECT * FROM {{ source('bronze', 'bz_support_tickets') }}
),

users_ref AS (
    SELECT user_id FROM {{ ref('si_users') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        bst.*,
        -- Quality score calculation
        CASE 
            WHEN bst.ticket_id IS NULL THEN 0
            WHEN bst.user_id IS NULL THEN 0.2
            WHEN bst.ticket_type IS NULL THEN 0.3
            WHEN bst.resolution_status IS NULL THEN 0.4
            WHEN bst.open_date IS NULL THEN 0.5
            WHEN u.user_id IS NULL THEN 0.6  -- User doesn't exist
            WHEN bst.ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 0.7
            WHEN bst.resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 0.8
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN bst.ticket_id IS NULL OR bst.user_id IS NULL THEN 'error'
            WHEN bst.ticket_type IS NULL OR bst.resolution_status IS NULL OR bst.open_date IS NULL THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_support_tickets bst
    LEFT JOIN users_ref u ON bst.user_id = u.user_id
),

-- Clean and transform data
cleaned_support_tickets AS (
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
            ELSE TRIM(ticket_type)
        END AS ticket_type,
        CASE 
            WHEN UPPER(TRIM(resolution_status)) = 'OPEN' THEN 'Open'
            WHEN UPPER(TRIM(resolution_status)) = 'IN PROGRESS' THEN 'In Progress'
            WHEN UPPER(TRIM(resolution_status)) = 'PENDING CUSTOMER' THEN 'Pending Customer'
            WHEN UPPER(TRIM(resolution_status)) = 'CLOSED' THEN 'Closed'
            WHEN UPPER(TRIM(resolution_status)) = 'RESOLVED' THEN 'Resolved'
            ELSE TRIM(resolution_status)
        END AS resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM dq_checks
    WHERE record_status = 'active'
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
FROM cleaned_support_tickets
