{{ config(
    materialized='table',
    tags=['bronze', 'customer']
) }}

WITH source_data AS (
    -- Extract raw customer data from source schema
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CREATED_DATE
    FROM {{ var('source_schema') }}.CUSTOMER_DETAILS
),

data_quality_checks AS (
    -- Apply data quality validations and transformations
    SELECT 
        -- 1-1 Mapping: Customer ID with validation
        CASE 
            WHEN CUSTOMER_ID IS NULL THEN -1
            ELSE CUSTOMER_ID
        END AS CUSTOMER_ID,
        
        -- 1-1 Mapping: Customer Name with data cleansing
        CASE 
            WHEN CUSTOMER_NAME IS NULL OR TRIM(CUSTOMER_NAME) = '' THEN 'UNKNOWN'
            ELSE TRIM(UPPER(CUSTOMER_NAME))
        END AS CUSTOMER_NAME,
        
        -- 1-1 Mapping: Email with validation
        CASE 
            WHEN EMAIL IS NULL OR TRIM(EMAIL) = '' THEN NULL
            WHEN EMAIL NOT LIKE '%@%' THEN NULL
            ELSE TRIM(LOWER(EMAIL))
        END AS EMAIL,
        
        -- 1-1 Mapping: Created Date with validation
        CASE 
            WHEN CREATED_DATE IS NULL THEN CURRENT_DATE()
            ELSE CREATED_DATE
        END AS CREATED_DATE,
        
        -- Audit columns for process tracking
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        CASE 
            WHEN CUSTOMER_ID IS NULL THEN 'ERROR'
            WHEN CUSTOMER_NAME IS NULL OR TRIM(CUSTOMER_NAME) = '' THEN 'WARNING'
            ELSE 'SUCCESS'
        END AS process_status
        
    FROM source_data
),

final_output AS (
    -- Final transformation with error handling
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CREATED_DATE,
        created_at,
        updated_at,
        process_status,
        
        -- Additional metadata for auditability
        'RAW.CUSTOMER_DETAILS' AS source_table,
        'BRONZE.CUSTOMER_DETAILS_BRZ' AS target_table,
        CURRENT_USER() AS processed_by
        
    FROM data_quality_checks
    WHERE CUSTOMER_ID != -1  -- Filter out records with invalid customer IDs
)

-- Return final bronze layer data
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    EMAIL,
    CREATED_DATE
FROM final_output
ORDER BY CUSTOMER_ID