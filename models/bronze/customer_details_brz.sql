{{ config(
    materialized='table',
    pre_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (table_name, process_status, process_start_time, process_end_time, record_count, created_at) VALUES ('{{ this.name }}', 'STARTED', CURRENT_TIMESTAMP, NULL, 0, CURRENT_TIMESTAMP){% endif %}",
    post_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (table_name, process_status, process_start_time, process_end_time, record_count, created_at) VALUES ('{{ this.name }}', 'COMPLETED', NULL, CURRENT_TIMESTAMP, (SELECT COUNT(*) FROM {{ this }}), CURRENT_TIMESTAMP){% endif %}"
) }}

/*
    Bronze Layer Transformation for Customer Details
    
    Purpose: Transform raw customer data into bronze layer with data quality checks
    Source: RAW.CUSTOMER_DETAILS
    Target: BRONZE.CUSTOMER_DETAILS_BRZ
    
    Transformation Rules:
    - 1:1 mapping for all fields
    - Data validation and cleansing
    - Audit trail implementation
*/

WITH source_data AS (
    -- Extract raw customer data with basic validation
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CREATED_DATE
    FROM {{ source('raw', 'customer_details') }}
    WHERE CUSTOMER_ID IS NOT NULL  -- Ensure primary key is not null
),

data_validation AS (
    -- Apply data quality checks and transformations
    SELECT 
        TRIM(CUSTOMER_ID) AS CUSTOMER_ID,
        TRIM(CUSTOMER_NAME) AS CUSTOMER_NAME,
        CASE 
            WHEN EMAIL IS NOT NULL AND EMAIL != '' 
            THEN LOWER(TRIM(EMAIL))
            ELSE NULL 
        END AS EMAIL,
        CREATED_DATE,
        -- Audit columns
        CURRENT_TIMESTAMP AS created_at,
        CURRENT_TIMESTAMP AS updated_at,
        'ACTIVE' AS process_status
    FROM source_data
    WHERE CUSTOMER_NAME IS NOT NULL  -- Ensure required fields are present
      AND CUSTOMER_NAME != ''
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
        process_status
    FROM data_validation
)

SELECT * FROM final_output
