{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_bz') }} (source_layer, source_table, target_layer, target_table, load_type, load_start_time, run_id, created_by) VALUES ('RAW', 'REGION', 'BRONZE', 'REGION', 'FULL', CURRENT_TIMESTAMP(), '{{ invocation_id }}', CURRENT_USER())",
    post_hook="UPDATE {{ ref('audit_log_bz') }} SET load_end_time = CURRENT_TIMESTAMP(), record_count_loaded = (SELECT COUNT(*) FROM {{ this }}), status = 'SUCCESS' WHERE run_id = '{{ invocation_id }}' AND target_table = 'REGION'"
) }}

WITH source_data AS (
    SELECT
        region_id,
        region_name,
        country,
        CURRENT_DATE() AS created_at,
        CURRENT_DATE() AS last_updated
    FROM {{ source('raw', 'region') }}
),

transformed_data AS (
    SELECT
        region_id,
        INITCAP(TRIM(region_name)) AS region_name,
        UPPER(TRIM(country)) AS country,
        created_at,
        last_updated,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS dbt_updated_at,
        '{{ invocation_id }}' AS dbt_batch_id
    FROM source_data
    WHERE region_id IS NOT NULL
      AND region_name IS NOT NULL
      AND country IS NOT NULL
)

SELECT * FROM transformed_data
