{{
  config(
    materialized='table',
    tags=['bronze', 'orders'],
    pre_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'ORDERS', 'BRONZE', 'ORDERS_BZ', 'FULL', CURRENT_TIMESTAMP, 'RUNNING', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'",
    post_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, LOAD_END_TIME, RECORD_COUNT_LOADED, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'ORDERS', 'BRONZE', 'ORDERS_BZ', 'FULL', CURRENT_TIMESTAMP - INTERVAL '1 MINUTE', CURRENT_TIMESTAMP, (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'"
  )
}}

-- Bronze layer transformation for ORDERS table
-- Transforms raw orders data with data quality checks and business logic

WITH source_data AS (
    SELECT 
        order_id,
        customer_id,
        product_name,
        quantity,
        price,
        order_date,
        -- Assuming these fields exist in raw based on mapping
        order_date AS shipped_date, -- Placeholder - adjust based on actual raw schema
        price * quantity AS order_amount,
        'PENDING' AS order_status, -- Placeholder - adjust based on actual raw schema
        order_date AS created_at,
        order_date AS last_updated
    FROM {{ source('raw_schema', 'orders') }}
),

-- Data transformations based on mapping requirements
transformed_data AS (
    SELECT 
        order_id,
        customer_id,
        order_date,
        shipped_date,
        order_amount,
        -- Standardize order status to uppercase as per mapping
        UPPER(TRIM(order_status)) AS order_status,
        -- Calculate order delay days as per mapping
        DATEDIFF('day', order_date, shipped_date) AS order_delay_days,
        created_at,
        last_updated,
        -- Add load date for tracking
        CURRENT_DATE() AS load_date,
        -- Add data quality flags
        CASE 
            WHEN order_id IS NULL THEN 'MISSING_ORDER_ID'
            WHEN customer_id IS NULL THEN 'MISSING_CUSTOMER_ID'
            WHEN order_date IS NULL THEN 'MISSING_ORDER_DATE'
            WHEN order_amount <= 0 THEN 'INVALID_AMOUNT'
            ELSE 'VALID'
        END AS data_quality_status
    FROM source_data
),

-- Filter out invalid records (optional - based on business rules)
final_data AS (
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
    WHERE data_quality_status = 'VALID'
        AND order_id IS NOT NULL
        AND customer_id IS NOT NULL
)

SELECT * FROM final_data
