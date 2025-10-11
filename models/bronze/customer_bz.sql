{{ config(
    materialized='table'
) }}

/*
    Bronze Layer Transformation for Customer Data
    Source: RAW.CUSTOMER
    Target: BRONZE.CUSTOMER_BZ
    
    Transformations Applied:
    - full_name: Concatenate first_name and last_name
    - Email validation and formatting
    - Phone number standardization
    - Add audit columns for tracking
*/

WITH source_data AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        phone_number,
        region_id,
        created_date
    FROM {{ source('raw_data', 'customer') }}
),

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN customer_id IS NULL THEN 'CUSTOMER_ID_NULL'
            WHEN first_name IS NULL OR TRIM(first_name) = '' THEN 'FIRST_NAME_INVALID'
            WHEN last_name IS NULL OR TRIM(last_name) = '' THEN 'LAST_NAME_INVALID'
            WHEN email IS NULL OR email = '' THEN 'EMAIL_INVALID'
            ELSE 'VALID'
        END as data_quality_flag
    FROM source_data
),

transformed_data AS (
    SELECT 
        customer_id,
        CONCAT(TRIM(first_name), ' ', TRIM(last_name)) as full_name,
        LOWER(TRIM(email)) as email,
        COALESCE(TRIM(phone_number), 'N/A') as phone_number,
        region_id,
        COALESCE(created_date, CURRENT_DATE()) as created_at,
        CURRENT_TIMESTAMP as last_updated,
        CURRENT_DATE() as load_date,
        data_quality_flag
    FROM data_quality_checks
    WHERE data_quality_flag = 'VALID'  -- Only load valid records
)

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
