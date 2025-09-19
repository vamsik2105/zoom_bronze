{{ config(
 materialized='table',
 schema='bronze',
 tags=['bronze', 'customer', 'daily'],

) }}
--  pre_hook="INSERT INTO {{ this.schema }}.audit_log VALUES ('{{ this.name }}', 'START',
-- CURRENT_TIMESTAMP())",
--  post_hook="INSERT INTO {{ this.schema }}.audit_log VALUES ('{{ this.name }}', 'COMPLETE',
-- CURRENT_TIMESTAMP())"
/*
================================================================================
Model: customer_details_brz
Description: Bronze layer transformation for customer details data
Project: Zoom_Customer_Analytics
Author: Data Engineering Team
Created: {{ run_started_at }}
================================================================================
Purpose:
- Transform raw customer data into bronze layer with data quality checks
- Implement 1:1 mapping from raw to bronze layer
- Add audit columns for data lineage and process tracking
- Apply data validation and error handling
Transformation Logic:
- Direct mapping of all fields from raw to bronze
- Data quality validation for required fields
- Deduplication based on customer_id
- Audit trail implementation
================================================================================
*/
WITH source_data AS (
 -- Extract raw customer data with basic validation
 SELECT 
 customer_id,
 customer_name,
 email,
 created_date,
 -- Add row number for deduplication (keep latest record per customer_id)
 ROW_NUMBER() OVER (
 PARTITION BY customer_id 
 ORDER BY created_date DESC, customer_name
 ) as row_num
 FROM {{ source('raw', 'customer_details') }}
 WHERE customer_id IS NOT NULL -- Ensure primary key is not null
),
validated_data AS (
 -- Apply data validation rules and quality checks
 SELECT 
 customer_id,
 customer_name,
 email,
 created_date,
 -- Data quality flags
 CASE 
 WHEN customer_name IS NULL OR TRIM(customer_name) = '' THEN 'INVALID_NAME'
 WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email,
'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'INVALID_EMAIL'
 WHEN created_date > CURRENT_DATE() THEN 'FUTURE_DATE'
 ELSE 'VALID'
 END as data_quality_status,
 
 -- Record processing metadata
 CURRENT_TIMESTAMP() as processed_at,
 '{{ invocation_id }}' as batch_id
 
 FROM source_data
 WHERE row_num = 1 -- Keep only one record per customer_id (deduplication)
),
final_bronze_data AS (
 -- Final transformation with audit columns
 SELECT 
 -- 1:1 Mapping from raw to bronze as per requirements
 customer_id,
 TRIM(customer_name) as customer_name, -- Clean whitespace
 LOWER(TRIM(email)) as email, -- Standardize email format
 created_date,
 
 -- Audit and process columns for bronze layer
 data_quality_status,
 processed_at as bronze_created_at,
 processed_at as bronze_updated_at,
 batch_id,
 
 -- Process status for monitoring
 CASE 
 WHEN data_quality_status = 'VALID' THEN 'SUCCESS'
 ELSE 'WARNING'
 END as process_status
 
 FROM validated_data
)
-- Final select with error handling
SELECT 
 customer_id,
 customer_name,
 email,
 created_date,
 data_quality_status,
 bronze_created_at,
 bronze_updated_at,
 batch_id,
 process_status
FROM final_bronze_data
-- Log any data quality issues for monitoring
{% if is_incremental() %}
 WHERE bronze_updated_at > (SELECT MAX(bronze_updated_at) FROM {{ this }})
{% endif %}