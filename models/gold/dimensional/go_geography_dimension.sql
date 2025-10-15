{{ config(
    materialized='table',
    pre_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date, update_date, source_system) VALUES (UUID_STRING(), 'go_geography_dimension_transform', 'SYSTEM', 'go_geography_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_DATE(), CURRENT_DATE(), 'DBT_TRANSFORM'){% endif %}",
    post_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date, update_date, source_system) VALUES (UUID_STRING(), 'go_geography_dimension_transform', 'SYSTEM', 'go_geography_dimension', 'COMPLETED', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), (SELECT COUNT(*) FROM {{ this }}), NULL, CURRENT_DATE(), CURRENT_DATE(), 'DBT_TRANSFORM'){% endif %}"
) }}

WITH default_geography AS (
    SELECT 
        'US' AS country_code,
        'United States' AS country_name,
        'North America' AS region_name,
        'UTC' AS time_zone,
        'North America' AS continent,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
    UNION ALL
    SELECT 
        'UNKNOWN' AS country_code,
        'Unknown Country' AS country_name,
        'Unknown Region' AS region_name,
        'UTC' AS time_zone,
        'Unknown Continent' AS continent,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
),

final_transformation AS (
    SELECT 
        UUID_STRING() AS geography_dim_id,
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
FROM final_transformation
