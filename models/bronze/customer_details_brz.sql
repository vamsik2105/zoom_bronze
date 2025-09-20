{{ config(
    materialized='table',
    schema='bronze',
    pre_hook="INSERT INTO {{ this.database }}.BRONZE.AUDIT_LOG (table_name, process_start_time, status) VALUES ('CUSTOMER_DETAILS_BRZ', CURRENT_TIMESTAMP(), 'STARTED')",
    post_hook="INSERT INTO {{ this.database }}.BRONZE.AUDIT_LOG (table_name, process_end_time, status) VALUES ('CUSTOMER_DETAILS_BRZ', CURRENT_TIMESTAMP(), 'COMPLETED')"
) }}

/*
    Bronze Layer Transformation for Customer Details
    Purpose: Transform raw customer data into bronze layer with data quality checks
    Source: RAW.CUSTOMER_DETAILS
    Target: BRONZE.CUSTOMER_DETAILS_BRZ
*/

WITH source_data AS (
    -- Extract raw customer data from source table
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CREATED_DATE
    FROM {{ source('raw', 'customer_details') }}
),

data_quality_checks AS (
    -- Apply data quality validations and cleansing
    SELECT 
        CUSTOMER_ID,
        TRIM(UPPER(CUSTOMER_NAME)) AS CUSTOMER_NAME,
        LOWER(TRIM(EMAIL)) AS EMAIL,
        CREATED_DATE,
        -- Data quality flags
        CASE 
            WHEN CUSTOMER_ID IS NULL THEN 'INVALID_ID'
            WHEN CUSTOMER_NAME IS NULL OR TRIM(CUSTOMER_NAME) = '' THEN 'INVALID_NAME'
            WHEN EMAIL IS NOT NULL AND NOT REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'INVALID_EMAIL'
            ELSE 'VALID'
        END AS data_quality_status
    FROM source_data
),

final_transformation AS (
    -- Final transformation with audit columns
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CREATED_DATE,
        -- Audit columns
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        data_quality_status AS process_status,
        '{{ run_started_at }}' AS dbt_run_timestamp,
        '{{ invocation_id }}' AS dbt_invocation_id
    FROM data_quality_checks
    WHERE data_quality_status = 'VALID'  -- Only include valid records
)

SELECT * FROM final_transformation