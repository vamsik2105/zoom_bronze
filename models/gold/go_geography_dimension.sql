{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) SELECT '{{ invocation_id }}_geo_dim', 'Geography Dimension Transform', 'Dimension Build', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE() WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}_geo_dim' AND status = 'STARTED' AND '{{ this.name }}' != 'go_process_audit'"
) }}

WITH default_geography AS (
    SELECT 
        'US' AS country_code,
        'United States' AS country_name,
        'North America' AS region_name,
        'UTC-5' AS time_zone,
        'North America' AS continent,
        'SYSTEM_GENERATED' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
),

geography_dimension_prep AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['country_code']) }} AS geography_dim_id,
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
FROM geography_dimension_prep
