{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_licenses', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', 0, 'STARTED')",
    post_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_licenses', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', DATEDIFF('second', (SELECT MAX(load_timestamp) FROM {{ this.schema }}.bz_audit_log WHERE source_table = 'bz_licenses' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
) }}

-- Bronze layer transformation for licenses table
SELECT 
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'licenses') }}
