{{ config(
    materialized='table'
) }}

WITH geography_base AS (
    SELECT DISTINCT
        'US' AS country_code,
        'United States' AS country_name,
        'North America' AS region_name,
        'UTC-5' AS time_zone,
        'North America' AS continent,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'DEFAULT' AS source_system
),

geography_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['country_code']) }} AS geography_dim_id,
        country_code,
        country_name,
        region_name,
        time_zone,
        continent,
        load_date,
        update_date,
        source_system
    FROM geography_base
)

SELECT
    geography_dim_id::VARCHAR(50) AS geography_dim_id,
    country_code::VARCHAR(10) AS country_code,
    country_name::VARCHAR(100) AS country_name,
    region_name::VARCHAR(100) AS region_name,
    time_zone::VARCHAR(50) AS time_zone,
    continent::VARCHAR(50) AS continent,
    load_date,
    update_date,
    source_system::VARCHAR(100) AS source_system
FROM geography_dimension
