{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed, load_date) VALUES ('{{ invocation_id }}', 'go_geography_dimension', 'DBT_MODEL', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', 'DBT_CLOUD', CURRENT_DATE())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), records_failed = 0, update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_geography_dimension'"
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
