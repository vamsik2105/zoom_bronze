{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, RECORD_COUNT_LOADED, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'CUSTOMER', 'BRONZE', 'CUSTOMER_BZ', 'FULL', CURRENT_TIMESTAMP, 0, 'STARTED', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'",
    post_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, LOAD_END_TIME, RECORD_COUNT_LOADED, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'CUSTOMER', 'BRONZE', 'CUSTOMER_BZ', 'FULL', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'"
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
        created_date as created_at,
        CURRENT_TIMESTAMP as last_updated
    FROM {{ source('raw_data', 'customer') }}
),

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN customer_id IS NULL THEN 'CUSTOMER_ID_NULL'
            WHEN first_name IS NULL OR TRIM(first_name) = '' THEN 'FIRST_NAME_INVALID'
            WHEN last_name IS NULL OR TRIM(last_name) = '' THEN 'LAST_NAME_INVALID'
            WHEN email IS NULL OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'EMAIL_INVALID'
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
        created_at,
        last_updated,
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
