{{ config(
    materialized='table',
    tags=['bronze', 'region']
) }}

WITH source_data AS (
    SELECT
        region_id,
        region_name,
        country
    FROM {{ source('raw', 'region') }}
),

transformed_data AS (
    SELECT
        region_id,
        INITCAP(region_name) AS region_name,
        UPPER(country) AS country,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        CURRENT_DATE() AS load_date
    FROM source_data
    WHERE region_id IS NOT NULL
)

SELECT * FROM transformed_data
