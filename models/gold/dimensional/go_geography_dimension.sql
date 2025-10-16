{{ config(
    materialized='table'
) }}

WITH geography_data AS (
    SELECT 
        'US' as country_code,
        'United States' as country_name,
        'North America' as region_name,
        'UTC-5' as time_zone,
        'North America' as continent,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'system' as source_system
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['country_code']) }} as geography_dim_id,
    country_code,
    country_name,
    region_name,
    time_zone,
    continent,
    load_date,
    update_date,
    source_system,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    'ACTIVE' as process_status
FROM geography_data
