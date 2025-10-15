{{
    config(
        materialized='incremental',
        unique_key='ticket_id',
        on_schema_change='fail'
    )
}}

-- Silver Support Tickets Transformation with Data Quality Checks
WITH source_data AS (
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY ticket_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     (CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN ticket_type IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN resolution_status IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN open_date IS NOT NULL THEN 1 ELSE 0 END) DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_support_tickets') }}
    WHERE ticket_id IS NOT NULL
    
    {% if is_incremental() %}
        AND update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
    {% endif %}
),

data_quality_checks AS (
    SELECT 
        *,
        -- Ticket type validation
        CASE 
            WHEN UPPER(TRIM(ticket_type)) IN ('AUDIO ISSUE', 'VIDEO ISSUE', 'CONNECTIVITY', 'BILLING INQUIRY', 'FEATURE REQUEST', 'ACCOUNT ACCESS') THEN 1
            ELSE 0
        END AS ticket_type_valid,
        
        -- Resolution status validation
        CASE 
            WHEN UPPER(TRIM(resolution_status)) IN ('OPEN', 'IN PROGRESS', 'PENDING CUSTOMER', 'CLOSED', 'RESOLVED') THEN 1
            ELSE 0
        END AS status_valid,
        
        -- User reference check
        CASE 
            WHEN user_id IS NOT NULL AND TRIM(user_id) != '' THEN 1
            ELSE 0
        END AS user_valid,
        
        -- Completeness check
        CASE 
            WHEN ticket_id IS NOT NULL AND user_id IS NOT NULL AND ticket_type IS NOT NULL 
                 AND resolution_status IS NOT NULL AND open_date IS NOT NULL THEN 1
            ELSE 0
        END AS completeness_check
    FROM source_data
    WHERE row_rank = 1
),

final_data AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(ticket_type)) IN ('AUDIO ISSUE', 'VIDEO ISSUE', 'CONNECTIVITY', 'BILLING INQUIRY', 'FEATURE REQUEST', 'ACCOUNT ACCESS') 
                 THEN UPPER(TRIM(ticket_type))
            ELSE 'OTHER'
        END AS ticket_type,
        CASE 
            WHEN UPPER(TRIM(resolution_status)) IN ('OPEN', 'IN PROGRESS', 'PENDING CUSTOMER', 'CLOSED', 'RESOLVED') 
                 THEN UPPER(TRIM(resolution_status))
            ELSE 'OPEN'
        END AS resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        ROUND((ticket_type_valid + status_valid + user_valid + completeness_check) / 4.0, 2) AS data_quality_score,
        CASE 
            WHEN ticket_type_valid = 1 AND status_valid = 1 AND user_valid = 1 AND completeness_check = 1 THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM data_quality_checks
)

SELECT * FROM final_data
WHERE record_status = 'active'  -- Only include valid records in Silver layer
