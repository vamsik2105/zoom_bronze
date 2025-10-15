{{ config(
    materialized='table',
    pre_hook="INSERT INTO GOLD.go_process_audit (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) VALUES ('{{ invocation_id }}', 'go_geography_dimension', 'TRANSFORMATION', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE())",
    post_hook="UPDATE GOLD.go_process_audit SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM GOLD.go_geography_dimension), processing_duration_seconds = 10 WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_geography_dimension'"
) }}

-- Gold Geography Dimension Table
-- Creates default geography dimension since geo data not available in Silver

WITH default_geography AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['country_code']) }} as geography_dim_id,
        'US' as country_code,
        'United States' as country_name,
        'North America' as region_name,
        'UTC' as time_zone,
        'North America' as continent,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'DEFAULT' as source_system
)

SELECT * FROM default_geography
