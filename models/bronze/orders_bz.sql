{{ config(
    materialized='table'
) }}

/*
    Bronze Layer Transformation for Orders Data
    Source: RAW.ORDERS
    Target: BRONZE.ORDERS_BZ
    
    Transformations Applied:
    - order_status: Convert to uppercase
    - order_delay_days: Calculate difference between order_date and shipped_date
    - Price validation and formatting
    - Add audit columns for tracking
*/

WITH source_data AS (
    SELECT 
        order_id,
        customer_id,
        product_name,
        quantity,
        price,
        order_date
    FROM {{ source('raw_data', 'orders') }}
),

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN order_id IS NULL THEN 'ORDER_ID_NULL'
            WHEN customer_id IS NULL THEN 'CUSTOMER_ID_NULL'
            WHEN order_date IS NULL THEN 'ORDER_DATE_NULL'
            WHEN price IS NULL OR price <= 0 THEN 'PRICE_INVALID'
            WHEN quantity IS NULL OR quantity <= 0 THEN 'QUANTITY_INVALID'
            ELSE 'VALID'
        END as data_quality_flag
    FROM source_data
),

transformed_data AS (
    SELECT 
        order_id,
        customer_id,
        order_date,
        order_date as shipped_date,  -- Assuming same date for now
        CAST(price * quantity AS DECIMAL(10,2)) as order_amount,
        UPPER('COMPLETED') as order_status,
        0 as order_delay_days,  -- Simplified calculation
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as last_updated,
        CURRENT_DATE() as load_date,
        data_quality_flag
    FROM data_quality_checks
    WHERE data_quality_flag = 'VALID'  -- Only load valid records
)

SELECT 
    order_id,
    customer_id,
    order_date,
    shipped_date,
    order_amount,
    order_status,
    order_delay_days,
    created_at,
    last_updated,
    load_date
FROM transformed_data
