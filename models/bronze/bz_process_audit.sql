-- Process audit for bronze layer transformations

{{ config(
    materialized = 'table',
    tags = ['bronze', 'audit']
) }}

-- This model runs after all other models and collects audit information
WITH model_stats AS (
    SELECT
        'bz_users' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_users') }}) as rows_processed,
        0 as execution_time_seconds
    UNION ALL
    SELECT
        'bz_meetings' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_meetings') }}) as rows_processed,
        0 as execution_time_seconds
    UNION ALL
    SELECT
        'bz_participants' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_participants') }}) as rows_processed,
        0 as execution_time_seconds
    UNION ALL
    SELECT
        'bz_feature_usage' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_feature_usage') }}) as rows_processed,
        0 as execution_time_seconds
    UNION ALL
    SELECT
        'bz_webinars' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_webinars') }}) as rows_processed,
        0 as execution_time_seconds
    UNION ALL
    SELECT
        'bz_support_tickets' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_support_tickets') }}) as rows_processed,
        0 as execution_time_seconds
    UNION ALL
    SELECT
        'bz_licenses' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_licenses') }}) as rows_processed,
        0 as execution_time_seconds
    UNION ALL
    SELECT
        'bz_billing_events' as model_name,
        CURRENT_TIMESTAMP() as run_timestamp,
        (SELECT COUNT(*) FROM {{ ref('bz_billing_events') }}) as rows_processed,
        0 as execution_time_seconds
)

SELECT
    model_name,
    run_timestamp,
    rows_processed,
    execution_time_seconds
FROM model_stats
