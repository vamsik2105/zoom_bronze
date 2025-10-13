{{
  config(
    materialized='table'
  )
}}

WITH source_data AS (
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

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE 
      WHEN ticket_id IS NULL THEN 'MISSING_TICKET_ID'
      WHEN user_id IS NULL THEN 'MISSING_USER_ID'
      WHEN ticket_type IS NULL THEN 'MISSING_TICKET_TYPE'
      WHEN resolution_status IS NULL THEN 'MISSING_RESOLUTION_STATUS'
      WHEN open_date IS NULL THEN 'MISSING_OPEN_DATE'
      ELSE 'VALID'
    END as completeness_status,
    
    -- Domain validation
    CASE 
      WHEN ticket_type IS NOT NULL AND ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 'INVALID_TICKET_TYPE'
      WHEN resolution_status IS NOT NULL AND resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 'INVALID_RESOLUTION_STATUS'
      ELSE 'VALID_DOMAIN'
    END as domain_status
  FROM source_data
),

-- Clean and transform data
cleaned_data AS (
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
    
    -- Calculate data quality score
    CASE 
      WHEN completeness_status != 'VALID' OR domain_status != 'VALID_DOMAIN' THEN 0.0
      WHEN ticket_id IS NOT NULL AND user_id IS NOT NULL AND ticket_type IS NOT NULL THEN 1.0
      ELSE 0.7
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN completeness_status = 'VALID' AND domain_status = 'VALID_DOMAIN' THEN 'active'
      ELSE 'error'
    END as record_status,
    
    completeness_status,
    domain_status
  FROM validated_data
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
FROM cleaned_data
WHERE record_status = 'active'
