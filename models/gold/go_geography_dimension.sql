{{ config(
    materialized='table'
) }}

-- Gold Geography Dimension Table
-- Creates default geography dimension since geo data not available in Silver

WITH default_geography AS (
    SELECT 
        'US' as country_code,
        'United States' as country_name,
        'North America' as region_name,
        'UTC' as time_zone,
        'North America' as continent,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'DEFAULT' as source_system
),

final_geography AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['country_code']) }} as geography_dim_id,
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

SELECT * FROM final_geography
