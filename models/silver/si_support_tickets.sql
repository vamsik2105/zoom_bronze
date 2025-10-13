{{ config(materialized='table') }}

-- Silver Support Tickets Table
WITH bronze_support_tickets AS (
    SELECT *
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

valid_users AS (
    SELECT DISTINCT user_id FROM {{ ref('si_users') }}
),

data_quality_checks AS (
    SELECT 
        bst.*,
        
        -- Completeness checks
        CASE WHEN ticket_id IS NULL THEN 1 ELSE 0 END as missing_ticket_id,
        CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as missing_user_id,
        CASE WHEN open_date IS NULL THEN 1 ELSE 0 END as missing_open_date,
        
        -- Domain validation
        CASE WHEN ticket_type IS NOT NULL AND ticket_type NOT IN 
             ('Audio Issue','Video Issue','Connectivity','Billing Inquiry','Feature Request','Account Access') 
             THEN 1 ELSE 0 END as invalid_ticket_type,
        CASE WHEN resolution_status IS NOT NULL AND resolution_status NOT IN 
             ('Open','In Progress','Pending Customer','Closed','Resolved') 
             THEN 1 ELSE 0 END as invalid_resolution_status,
        
        -- Referential integrity
        CASE WHEN vu.user_id IS NULL THEN 1 ELSE 0 END as invalid_user_ref,
        
        -- Calculate data quality score
        CASE 
            WHEN ticket_id IS NULL OR user_id IS NULL OR open_date IS NULL THEN 0.0
            WHEN vu.user_id IS NULL THEN 0.2
            WHEN ticket_type NOT IN ('Audio Issue','Video Issue','Connectivity','Billing Inquiry','Feature Request','Account Access') THEN 0.4
            WHEN resolution_status NOT IN ('Open','In Progress','Pending Customer','Closed','Resolved') THEN 0.6
            ELSE 1.0
        END as data_quality_score
    FROM bronze_support_tickets bst
    LEFT JOIN valid_users vu ON bst.user_id = vu.user_id
)

SELECT 
    ticket_id,
    user_id,
    CASE 
        WHEN ticket_type IN ('Audio Issue','Video Issue','Connectivity','Billing Inquiry','Feature Request','Account Access') 
        THEN ticket_type
        ELSE 'Other'  -- Standardize invalid values
    END as ticket_type,
    CASE 
        WHEN resolution_status IN ('Open','In Progress','Pending Customer','Closed','Resolved') 
        THEN resolution_status
        ELSE 'Open'  -- Default to Open for invalid values
    END as resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    data_quality_score,
    CASE 
        WHEN missing_ticket_id = 1 OR missing_user_id = 1 OR missing_open_date = 1 OR invalid_user_ref = 1
        THEN 'error'
        ELSE 'active'
    END as record_status
FROM data_quality_checks
WHERE CASE 
        WHEN missing_ticket_id = 1 OR missing_user_id = 1 OR missing_open_date = 1 OR invalid_user_ref = 1
        THEN 'error'
        ELSE 'active'
    END = 'active'
