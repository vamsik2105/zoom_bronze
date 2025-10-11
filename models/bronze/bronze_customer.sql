{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_bz') }} (source_layer, source_table, target_layer, target_table, load_type, load_start_time, run_id, created_by) VALUES ('RAW', 'CUSTOMER', 'BRONZE', 'CUSTOMER', 'FULL', CURRENT_TIMESTAMP(), '{{ invocation_id }}', CURRENT_USER())",
    post_hook="UPDATE {{ ref('audit_log_bz') }} SET load_end_time = CURRENT_TIMESTAMP(), record_count_loaded = (SELECT COUNT(*) FROM {{ this }}), status = 'SUCCESS' WHERE run_id = '{{ invocation_id }}' AND target_table = 'CUSTOMER'"
) }}

WITH source_data AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        phone_number,
        region_id,
        created_date AS created_at,
        created_date AS last_updated  -- Assuming same as created_date since not in source
    FROM {{ source('raw', 'customer') }}
),

transformed_data AS (
    SELECT
        customer_id,
        CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, '')) AS full_name,
        LOWER(TRIM(email)) AS email,
        phone_number,
        region_id,
        created_at,
        last_updated,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS dbt_updated_at,
        '{{ invocation_id }}' AS dbt_batch_id
    FROM source_data
    WHERE customer_id IS NOT NULL
      AND email IS NOT NULL
      AND email LIKE '%@%'  -- Basic email validation
)

SELECT * FROM transformed_data
