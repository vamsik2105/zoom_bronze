{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_audit_log', CURRENT_TIMESTAMP, 'dbt', 0, 'STARTED') WHERE FALSE",
    post_hook="INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_audit_log', CURRENT_TIMESTAMP, 'dbt', 0, 'COMPLETED')"
) }}

-- Bronze Audit Log Table
-- This table tracks all bronze layer processing activities

SELECT 
    CAST(NULL AS NUMBER) AS record_id,
    CAST('INITIAL_LOAD' AS VARCHAR(255)) as source_table,
    CURRENT_TIMESTAMP as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status

WHERE FALSE -- This ensures the table structure is created but no initial data is inserted
