{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_bz') }} (source_layer, source_table, target_layer, target_table, load_type, load_start_time, run_id, created_by) VALUES ('RAW', 'ORDERS', 'BRONZE', 'ORDERS', 'FULL', CURRENT_TIMESTAMP(), '{{ invocation_id }}', CURRENT_USER())",
    post_hook="UPDATE {{ ref('audit_log_bz') }} SET load_end_time = CURRENT_TIMESTAMP(), record_count_loaded = (SELECT COUNT(*) FROM {{ this }}), status = 'SUCCESS' WHERE run_id = '{{ invocation_id }}' AND target_table = 'ORDERS'"
) }}

WITH source_data AS (
    SELECT
        order_id,
        customer_id,
        product_name,
        quantity,
        price,
        order_date,
        order_date AS shipped_date,  -- Assuming same as order_date since not in source
        (quantity * price) AS order_amount,
        'COMPLETED' AS order_status,  -- Default status since not in source
        order_date AS created_at,
        order_date AS last_updated
    FROM {{ source('raw', 'orders') }}
),

transformed_data AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        shipped_date,
        order_amount,
        UPPER(TRIM(order_status)) AS order_status,
        DATEDIFF('day', order_date, shipped_date) AS order_delay_days,
        created_at,
        last_updated,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS dbt_updated_at,
        '{{ invocation_id }}' AS dbt_batch_id
    FROM source_data
    WHERE order_id IS NOT NULL
      AND customer_id IS NOT NULL
      AND order_amount > 0
      AND quantity > 0
)

SELECT * FROM transformed_data
