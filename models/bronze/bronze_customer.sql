{{ config(
    materialized='table',
    tags=['bronze', 'customer']
) }}

WITH source_data AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        phone_number,
        region_id,
        created_date
    FROM {{ source('raw', 'customer') }}
),

transformed_data AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        CONCAT(first_name, ' ', last_name) AS full_name,
        email,
        phone_number,
        region_id,
        created_date,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        CURRENT_DATE() AS load_date
    FROM source_data
    WHERE customer_id IS NOT NULL
)

SELECT * FROM transformed_data
