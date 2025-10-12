-- =====================================================
-- SILVER SUPPORT TICKETS MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

WITH bronze_support_tickets AS (
    SELECT *
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN ticket_id IS NULL THEN 0 ELSE 1 END as ticket_id_check,
        CASE WHEN user_id IS NULL THEN 0 ELSE 1 END as user_id_check,
        CASE WHEN ticket_type IS NULL THEN 0 ELSE 1 END as ticket_type_check,
        CASE WHEN resolution_status IS NULL THEN 0 ELSE 1 END as resolution_status_check,
        CASE WHEN open_date IS NULL THEN 0 ELSE 1 END as open_date_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Domain checks
        CASE WHEN ticket_type IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 1 ELSE 0 END as ticket_type_domain_check,
        CASE WHEN resolution_status IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 1 ELSE 0 END as resolution_status_domain_check
    FROM bronze_support_tickets
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (ticket_id_check + user_id_check + ticket_type_check + resolution_status_check + 
             open_date_check + source_system_check + ticket_type_domain_check + resolution_status_domain_check) / 8.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN ticket_id IS NULL OR user_id IS NULL OR ticket_type IS NULL OR resolution_status IS NULL OR open_date IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 'ERROR'
            WHEN resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN ticket_type IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN ticket_type
            ELSE 'Other'
        END as ticket_type,
        CASE 
            WHEN resolution_status IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN resolution_status
            ELSE 'Open'
        END as resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        record_status
    FROM quality_scored
    WHERE record_status = 'ACTIVE'
)

SELECT * FROM final_support_tickets
