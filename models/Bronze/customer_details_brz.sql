-- # DBT Model File (`models/bronze/customer_details_brz.sql`)

{{ config(
materialized='table',
tags=['bronze', 'customer'],
pre_hook="INSERT INTO {{ this.schema }}.audit_log VALUES ('{{ this.name }}', 'START', CURRENT_TIMESTAMP())",
post_hook="INSERT INTO {{ this.schema }}.audit_log VALUES ('{{ this.name }}', 'END', CURRENT_TIMESTAMP())"
) }}

/*
================================================================================
Model: customer_details_brz
Description: Bronze layer transformation for customer details data
Source: raw.customer_details
Target: bronze.customer_details_brz
Transformation Type: 1-to-1 mapping with data quality checks and audit columns
================================================================================
*/

WITH source_data AS (
-- Extract raw customer data with basic validation
SELECT
customer_id,
customer_name,
email,
created_date,
-- Add row-level metadata for tracking
CURRENT_TIMESTAMP() AS extraction_timestamp
FROM {{ source('raw', 'customer_details') }}
),

data_quality_checks AS (
-- Apply data quality validations and cleansing
SELECT
customer_id,
-- Clean and validate customer name
CASE
WHEN TRIM(customer_name) = '' OR customer_name IS NULL
THEN 'UNKNOWN_CUSTOMER'
ELSE TRIM(UPPER(customer_name))
END AS customer_name,

-- Clean and validate email format
CASE
WHEN email IS NULL OR TRIM(email) = ''
THEN NULL
WHEN REGEXP_LIKE(LOWER(TRIM(email)), '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$')
THEN LOWER(TRIM(email))
ELSE 'INVALID_EMAIL'
END AS email,

-- Validate created_date
CASE
WHEN created_date IS NULL
THEN CURRENT_DATE()
WHEN created_date > CURRENT_DATE()
THEN CURRENT_DATE()
ELSE created_date
END AS created_date,

extraction_timestamp,

-- Add data quality flags
CASE
WHEN customer_id IS NULL THEN 'MISSING_ID'
WHEN TRIM(customer_name) = '' OR customer_name IS NULL THEN 'MISSING_NAME'
WHEN email IS NOT NULL AND NOT REGEXP_LIKE(LOWER(TRIM(email)), '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$') THEN 'INVALID_EMAIL_FORMAT'
WHEN created_date > CURRENT_DATE() THEN 'FUTURE_DATE'
ELSE 'VALID'
END AS data_quality_status

FROM source_data
-- Filter out records with null customer_id as it's the primary key
WHERE customer_id IS NOT NULL
),

final_bronze_layer AS (
-- Final transformation with audit columns
SELECT
-- Business columns (1-to-1 mapping as specified)
customer_id,
customer_name,
email,
created_date,

-- Process audit columns
CURRENT_TIMESTAMP() AS created_at,
CURRENT_TIMESTAMP() AS updated_at,
data_quality_status AS process_status,
'{{ run_started_at }}' AS dbt_run_timestamp,
'{{ invocation_id }}' AS dbt_invocation_id,

-- Additional metadata for debugging and lineage
extraction_timestamp,
'bronze_layer_processing' AS processing_stage

FROM data_quality_checks
)

-- Return final bronze layer data
SELECT
customer_id,
customer_name,
email,
created_date,
created_at,
updated_at,
process_status,
dbt_run_timestamp,
dbt_invocation_id,
extraction_timestamp,
processing_stage
FROM final_bronze_layer

-- Add data quality monitoring
{% if is_incremental() %}
-- For incremental runs, only process new or updated records
WHERE extraction_timestamp > (SELECT MAX(extraction_timestamp) FROM {{ this }})
{% endif %}

-- Order by customer_id for consistent output
ORDER BY customer_id
