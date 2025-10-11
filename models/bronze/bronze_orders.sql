{{ config(
    materialized='table',
    tags=['bronze', 'orders']
) }}

WITH source_data AS (
    SELECT
        order_id,
        customer_id,
        product_name,
        quantity,
        price,
        order_date
    FROM {{ source('raw', 'orders') }}
),

transformed_data AS (
    SELECT
        order_id,
        customer_id,
        product_name,
        quantity,
        price,
        order_date,
        order_date AS shipped_date,  -- Assuming same as order_date since not in source
        UPPER('COMPLETED') AS order_status,  -- Default status
        DATEDIFF('day', order_date, order_date) AS order_delay_days, -- Will be 0
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        CURRENT_DATE() AS load_date
    FROM source_data
    WHERE order_id IS NOT NULL
      AND customer_id IS NOT NULL
)

SELECT * FROM transformed_data
