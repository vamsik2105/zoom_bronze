{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_meetings', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', 0, 'STARTED')",
    post_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_meetings', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', DATEDIFF('second', (SELECT MAX(load_timestamp) FROM {{ this.schema }}.bz_audit_log WHERE source_table = 'bz_meetings' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
) }}

-- Bronze layer transformation for meetings table
SELECT 
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'meetings') }}
