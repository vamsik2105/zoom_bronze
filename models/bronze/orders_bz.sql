{{ config(
    materialized='table'
) }}

-- Bronze Layer Transformation for Orders Data
SELECT 
    order_id,
    customer_id,
    order_date,
    order_date as shipped_date,
    (price * quantity) as order_amount,
    'COMPLETED' as order_status,
    0 as order_delay_days,
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as last_updated,
    CURRENT_DATE() as load_date
FROM RAW.ORDERS
WHERE order_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND order_date IS NOT NULL
  AND price > 0
  AND quantity > 0
