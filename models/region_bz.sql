-- Bronze Layer Transformation for Region Data
SELECT 
    region_id,
    INITCAP(region_name) as region_name,
    UPPER(country) as country,
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as last_updated,
    CURRENT_DATE() as load_date
FROM {{ source('raw', 'region') }}
WHERE region_id IS NOT NULL
