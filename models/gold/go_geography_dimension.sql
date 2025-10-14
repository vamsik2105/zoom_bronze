{{ config(
    materialized='table'
) }}

-- Gold Geography Dimension Table
-- Note: Geography table not available in Silver, creating default geography
WITH default_geography AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['"DEFAULT_GEO"']) }} AS geography_dim_id,
        'US' AS country_code,
        'United States' AS country_name,
        'North America' AS region_name,
        'UTC' AS time_zone,
        'North America' AS continent,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'SYSTEM_GENERATED' AS source_system
)

SELECT * FROM default_geography
