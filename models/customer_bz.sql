-- Bronze Layer Transformation for Customer Data
SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) as full_name,
    LOWER(email) as email,
    COALESCE(phone_number, 'N/A') as phone_number,
    region_id,
    COALESCE(created_date, CURRENT_DATE()) as created_at,
    CURRENT_TIMESTAMP as last_updated,
    CURRENT_DATE() as load_date
FROM {{ source('raw', 'customer') }}
WHERE customer_id IS NOT NULL
