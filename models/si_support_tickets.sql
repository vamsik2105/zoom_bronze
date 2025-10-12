-- Silver layer support tickets table with data quality checks and transformations
-- Transforms bronze support tickets data with validation and cleansing

{{ config(
    materialized='table'
) }}

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

-- Data quality validation
validated_support_tickets AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN ticket_id IS NULL THEN 1 ELSE 0 END as null_ticket_id,
        CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as null_user_id,
        CASE WHEN open_date IS NULL THEN 1 ELSE 0 END as null_open_date,
        
        -- Domain validation
        CASE WHEN ticket_type IS NOT NULL AND ticket_type NOT IN ('Audio Issue','Video Issue','Connectivity','Billing Inquiry','Feature Request','Account Access') 
             THEN 1 ELSE 0 END as invalid_ticket_type,
        CASE WHEN resolution_status IS NOT NULL AND resolution_status NOT IN ('Open','In Progress','Pending Customer','Closed','Resolved') 
             THEN 1 ELSE 0 END as invalid_resolution_status
    FROM bronze_support_tickets
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
            ELSE ticket_type
        END as ticket_type,
        CASE 
            WHEN UPPER(TRIM(resolution_status)) = 'OPEN' THEN 'Open'
            WHEN UPPER(TRIM(resolution_status)) = 'IN PROGRESS' THEN 'In Progress'
            WHEN UPPER(TRIM(resolution_status)) = 'PENDING CUSTOMER' THEN 'Pending Customer'
            WHEN UPPER(TRIM(resolution_status)) = 'CLOSED' THEN 'Closed'
            WHEN UPPER(TRIM(resolution_status)) = 'RESOLVED' THEN 'Resolved'
            ELSE resolution_status
        END as resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        
        -- Data quality flags
        null_ticket_id + null_user_id + null_open_date + invalid_ticket_type + invalid_resolution_status as error_count,
        
        -- Record status
        CASE 
            WHEN null_ticket_id = 1 OR null_user_id = 1 OR null_open_date = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_support_tickets
),

-- Calculate data quality score
final_support_tickets AS (
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
        
        -- Data quality score calculation
        CASE 
            WHEN error_count = 0 THEN 1.0
            WHEN error_count = 1 THEN 0.8
            WHEN error_count = 2 THEN 0.6
            WHEN error_count = 3 THEN 0.4
            WHEN error_count = 4 THEN 0.2
            ELSE 0.0
        END as data_quality_score,
        
        record_status
    FROM cleaned_support_tickets
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_support_tickets
