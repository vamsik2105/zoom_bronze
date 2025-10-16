{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, created_at, updated_at) VALUES (UUID_STRING(), 'geography_dimension_transformation', 'derived', 'go_geography_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}), updated_at = CURRENT_TIMESTAMP() WHERE process_name = 'geography_dimension_transformation' AND process_status = 'STARTED'"
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
    UUID_STRING() as geography_dim_id,
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
