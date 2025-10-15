{{ config(
    materialized='table'
) }}

WITH default_geography AS (
    SELECT 
        'US' AS country_code,
        'United States' AS country_name,
        'North America' AS region_name,
        'UTC' AS time_zone,
        'North America' AS continent,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
    UNION ALL
    SELECT 
        'UNKNOWN' AS country_code,
        'Unknown Country' AS country_name,
        'Unknown Region' AS region_name,
        'UTC' AS time_zone,
        'Unknown Continent' AS continent,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
),

final_transformation AS (
    SELECT 
        CONCAT('GEO_', ROW_NUMBER() OVER (ORDER BY country_code)) AS geography_dim_id,
        country_code,
        country_name,
        region_name,
        time_zone,
        continent,
        load_date,
        update_date,
        source_system
    FROM default_geography
)

SELECT 
    geography_dim_id,
    country_code,
    country_name,
    region_name,
    time_zone,
    continent,
    load_date,
    update_date,
    source_system
FROM final_transformation
