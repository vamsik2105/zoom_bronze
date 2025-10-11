{{ config(
    materialized='table',
    tags=['audit', 'bronze'],
    post_hook="INSERT INTO {{ ref('audit_log_bz') }} (audit_id, source_layer, source_table, target_layer, target_table, load_type, load_start_time, load_end_time, record_count_loaded, status, run_id, created_by, created_at) VALUES (1, 'RAW', 'CUST', 'BRONZE', 'CUST', 'FULL', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), (SELECT COUNT(*) FROM {{ ref('bronze_customer') }}), 'SUCCESS', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP());"
) }}

-- This is a dummy model that just serves to run the post-hook
SELECT
    1 AS id,
    'AUDIT' AS type,
    CURRENT_TIMESTAMP() AS created_at
