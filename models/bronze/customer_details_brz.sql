{{ config(
    materialized='table',
    schema='bronze',
    tags=['bronze', 'customer'],
    pre_hook="INSERT INTO {{ ref('audit_log') }} VALUES ('{{ this }}', 'customer_details_brz', 'STARTED', CURRENT_TIMESTAMP())",
    post_hook="INSERT INTO {{ ref('audit_log') }} VALUES ('{{ this }}', 'customer_details_brz', 'COMPLETED', CURRENT_TIMESTAMP())"
) }}

/*
================================================================================
DBT Model: customer_details_brz
Project: Zoom_Customer_Analytics
Layer: Bronze
Description: Transform raw customer details data into bronze layer with 
             data quality checks and audit information
Author: Data Engineering Team
Created: {{ run_started_at }}
================================================================================
*/

WITH source_data AS (
    -- Extract raw customer data from source table
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CREATED_DATE
    FROM {{ source('raw', 'CUSTOMER_DETAILS') }}
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
            ELSE UPPER(TRIM(CUSTOMER_NAME))
        END AS CUSTOMER_NAME,
        
        -- 1-1 Mapping: Email with validation
        CASE 
            WHEN EMAIL IS NULL OR TRIM(EMAIL) = '' THEN NULL
            WHEN EMAIL NOT LIKE '%@%' THEN NULL
            ELSE LOWER(TRIM(EMAIL))
        END AS EMAIL,
        
        -- 1-1 Mapping: Created Date with validation
        CASE 
            WHEN CREATED_DATE IS NULL THEN CURRENT_DATE()
            WHEN CREATED_DATE > CURRENT_DATE() THEN CURRENT_DATE()
            ELSE CREATED_DATE
        END AS CREATED_DATE,
        
        -- Audit and process tracking columns
        CURRENT_TIMESTAMP() AS bronze_created_at,
        CURRENT_TIMESTAMP() AS bronze_updated_at,
        CASE 
            WHEN CUSTOMER_ID IS NULL THEN 'ERROR_MISSING_ID'
            WHEN CUSTOMER_NAME IS NULL OR TRIM(CUSTOMER_NAME) = '' THEN 'WARNING_MISSING_NAME'
            WHEN EMAIL IS NOT NULL AND EMAIL NOT LIKE '%@%' THEN 'WARNING_INVALID_EMAIL'
            ELSE 'SUCCESS'
        END AS process_status,
        
        -- Data lineage tracking
        '{{ invocation_id }}' AS dbt_run_id,
        '{{ run_started_at }}' AS dbt_run_timestamp
        
    FROM source_data
),

final_bronze_data AS (
    -- Final selection with error handling
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CREATED_DATE,
        bronze_created_at,
        bronze_updated_at,
        process_status,
        dbt_run_id,
        dbt_run_timestamp
    FROM data_quality_checks
    -- Filter out records with critical errors (optional based on business rules)
    WHERE process_status != 'ERROR_MISSING_ID'
)

-- Final output to bronze table
SELECT * FROM final_bronze_data
