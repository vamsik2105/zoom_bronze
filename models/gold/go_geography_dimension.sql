{{ config(
    materialized='table'
) }}

WITH final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['1']) }} as geography_dim_id,
        'US' as country_code,
        'United States' as country_name,
        'North America' as region_name,
        'UTC-5' as time_zone,
        'North America' as continent,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'SYSTEM' as source_system
)

SELECT * FROM final
