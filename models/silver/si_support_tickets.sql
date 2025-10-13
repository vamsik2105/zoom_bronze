{{ config(materialized='table') }}

WITH bronze_support_tickets AS (
    SELECT *
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

-- Data Quality Checks
quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN ticket_id IS NULL THEN 0 ELSE 1 END as ticket_id_complete,
        CASE WHEN user_id IS NULL THEN 0 ELSE 1 END as user_id_complete,
        CASE WHEN open_date IS NULL THEN 0 ELSE 1 END as open_date_complete,
        
        -- Domain checks
        CASE WHEN ticket_type IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 1 ELSE 0 END as ticket_type_valid,
        CASE WHEN resolution_status IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 1 ELSE 0 END as resolution_status_valid
    FROM bronze_support_tickets
),

-- Calculate data quality score
scored_data AS (
    SELECT 
        *,
        ROUND(
            (ticket_id_complete + user_id_complete + open_date_complete + ticket_type_valid + resolution_status_valid) / 5.0, 2
        ) as data_quality_score,
        CASE 
            WHEN ticket_id IS NULL OR user_id IS NULL OR open_date IS NULL THEN 'error'
            ELSE 'active'
        END as record_status
    FROM quality_checks
),

-- Final transformation
final_data AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN ticket_type IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN ticket_type
            ELSE 'Other'
        END as ticket_type,
        CASE 
            WHEN resolution_status IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN resolution_status
            ELSE 'Unknown'
        END as resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        record_status
    FROM scored_data
    WHERE record_status = 'active'
)

SELECT * FROM final_data
