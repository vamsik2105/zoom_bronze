{{ config(materialized='table') }}

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
    CASE WHEN ticket_id IS NULL THEN 1 ELSE 0 END as null_ticket_id,
    CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as null_user_id,
    CASE WHEN open_date IS NULL THEN 1 ELSE 0 END as null_open_date,
    
    -- Domain validation
    CASE WHEN ticket_type IS NOT NULL AND ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 1 ELSE 0 END as invalid_ticket_type,
    CASE WHEN resolution_status IS NOT NULL AND resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 1 ELSE 0 END as invalid_resolution_status
  FROM source_data
),

-- Clean and transform data
transformed_data AS (
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
    END as ticket_type,
    CASE 
      WHEN UPPER(resolution_status) = 'OPEN' THEN 'Open'
      WHEN UPPER(resolution_status) = 'IN PROGRESS' THEN 'In Progress'
      WHEN UPPER(resolution_status) = 'PENDING CUSTOMER' THEN 'Pending Customer'
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
    
    -- Calculate data quality score
    CASE 
      WHEN (null_ticket_id + null_user_id + null_open_date + invalid_ticket_type + invalid_resolution_status) = 0 THEN 1.0
      WHEN (null_ticket_id + null_user_id + null_open_date + invalid_ticket_type + invalid_resolution_status) <= 2 THEN 0.8
      WHEN (null_ticket_id + null_user_id + null_open_date + invalid_ticket_type + invalid_resolution_status) <= 3 THEN 0.6
      ELSE 0.4
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN (null_ticket_id + null_user_id + null_open_date) > 0 THEN 'error'
      WHEN (invalid_ticket_type + invalid_resolution_status) > 0 THEN 'warning'
      ELSE 'active'
    END as record_status
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
FROM transformed_data
