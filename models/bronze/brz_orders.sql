{{ config(
    schema= 'BRONZE',
materialized='table'
) }}
-- pre_hook="INSERT INTO {{ this.schema }}.audit_log VALUES ('{{ this.name }}', 'STARTED', CURRENT_TIMESTAMP())",
-- post_hook="INSERT INTO {{ this.schema }}.audit_log VALUES ('{{ this.name }}', 'COMPLETED', CURRENT_TIMESTAMP())"

/*
================================================================================
DBT Model: Bronze Orders Transformation
================================================================================
Purpose: Transform raw orders data into bronze layer with data quality checks
Source: ORDERS_RAW table
Target: ORDERS_BRZ table
Author: Data Engineering Team
Created: {{ run_started_at }}
================================================================================
*/

WITH source_data AS (
-- Extract raw orders data with basic validation
SELECT
ORDER_ID,
CUSTOMER_ID,
PRODUCT_NAME,
QUANTITY,
PRICE,
ORDER_DATE,
-- Add row identification for debugging
ROW_NUMBER() OVER (ORDER BY ORDER_ID) as row_num
FROM {{ source('raw', 'orders_raw') }}
WHERE ORDER_ID IS NOT NULL -- Basic null check for primary key
),

data_quality_checks AS (
-- Apply data quality validations and flag potential issues
SELECT
*,
CASE
WHEN ORDER_ID IS NULL THEN 'MISSING_ORDER_ID'
WHEN CUSTOMER_ID IS NULL THEN 'MISSING_CUSTOMER_ID'
WHEN PRODUCT_NAME IS NULL OR TRIM(PRODUCT_NAME) = '' THEN 'MISSING_PRODUCT_NAME'
WHEN QUANTITY IS NULL OR QUANTITY <= 0 THEN 'INVALID_QUANTITY'
WHEN PRICE IS NULL OR PRICE < 0 THEN 'INVALID_PRICE'
WHEN ORDER_DATE IS NULL THEN 'MISSING_ORDER_DATE'
WHEN ORDER_DATE > CURRENT_DATE() THEN 'FUTURE_ORDER_DATE'
ELSE 'VALID'
END as data_quality_flag,

-- Calculate derived fields for audit purposes
CASE
WHEN QUANTITY IS NOT NULL AND PRICE IS NOT NULL
THEN QUANTITY * PRICE
ELSE NULL
END as total_amount

FROM source_data
),

deduplication AS (
-- Remove duplicates based on ORDER_ID, keeping the latest record
SELECT
*,
ROW_NUMBER() OVER (
PARTITION BY ORDER_ID
ORDER BY ORDER_DATE DESC, row_num DESC
) as duplicate_rank
FROM data_quality_checks
),

final_transformation AS (
-- Final data selection and transformation with audit columns
SELECT
-- Direct mapping fields as per specification
ORDER_ID,
CUSTOMER_ID,
PRODUCT_NAME,
QUANTITY,
PRICE,
ORDER_DATE,

-- Audit and process tracking columns
data_quality_flag as process_status,
total_amount,
CURRENT_TIMESTAMP() as created_at,
CURRENT_TIMESTAMP() as updated_at,
'{{ invocation_id }}' as dbt_run_id,
'{{ run_started_at }}' as process_timestamp

FROM deduplication
WHERE duplicate_rank = 1 -- Keep only unique records
AND data_quality_flag = 'VALID' -- Only process valid records
)

-- Final select with error handling
SELECT
ORDER_ID,
CUSTOMER_ID,
PRODUCT_NAME,
QUANTITY,
PRICE,
ORDER_DATE
FROM final_transformation

{#
Add data quality test at runtime
{% if execute %}
{% set quality_check_query %}
SELECT COUNT(*) as failed_records
FROM data_quality_checks
WHERE data_quality_flag != 'VALID'
{% endset %}

{% set results = run_query(quality_check_query) %}
{% if results %}
{% set failed_count = results.columns[0].values()[0] %}
{% if failed_count > 0 %}
{{ log("WARNING: " ~ failed_count ~ " records failed data quality checks", info=True) }}
{% endif %}
{% endif %}
{% endif %}
#}