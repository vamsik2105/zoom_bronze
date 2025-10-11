{{
  config(
    materialized='table',
    tags=['bronze', 'customer'],
    pre_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'CUSTOMER', 'BRONZE', 'CUSTOMER_BZ', 'FULL', CURRENT_TIMESTAMP, 'RUNNING', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'",
    post_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, LOAD_END_TIME, RECORD_COUNT_LOADED, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'CUSTOMER', 'BRONZE', 'CUSTOMER_BZ', 'FULL', CURRENT_TIMESTAMP - INTERVAL '1 MINUTE', CURRENT_TIMESTAMP, (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'"
  )
}}

-- Bronze layer transformation for CUSTOMER table
-- Transforms raw customer data with data quality checks and standardization

WITH source_data AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        phone_number,
        region_id,
        created_date AS created_at,
        created_date AS last_updated
    FROM {{ source('raw_schema', 'customer') }}
),

-- Data transformations based on mapping requirements
transformed_data AS (
    SELECT 
        customer_id,
        -- Concatenate first and last name as per mapping
        CONCAT(TRIM(first_name), ' ', TRIM(last_name)) AS full_name,
        -- Standardize email to lowercase
        LOWER(TRIM(email)) AS email,
        -- Clean phone number
        TRIM(phone_number) AS phone_number,
        region_id,
        created_at,
        last_updated,
        -- Add load date for tracking
        CURRENT_DATE() AS load_date,
        -- Add data quality flags
        CASE 
            WHEN customer_id IS NULL THEN 'MISSING_ID'
            WHEN first_name IS NULL OR TRIM(first_name) = '' THEN 'MISSING_FIRST_NAME'
            WHEN last_name IS NULL OR TRIM(last_name) = '' THEN 'MISSING_LAST_NAME'
            WHEN email IS NULL OR TRIM(email) = '' THEN 'MISSING_EMAIL'
            WHEN email NOT LIKE '%@%' THEN 'INVALID_EMAIL'
            ELSE 'VALID'
        END AS data_quality_status
    FROM source_data
),

-- Filter out invalid records (optional - based on business rules)
final_data AS (
    SELECT 
        customer_id,
        full_name,
        email,
        phone_number,
        region_id,
        created_at,
        last_updated,
        load_date
    FROM transformed_data
    WHERE data_quality_status = 'VALID'
        AND customer_id IS NOT NULL
)

SELECT * FROM final_data
