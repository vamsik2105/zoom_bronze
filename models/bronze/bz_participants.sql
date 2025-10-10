{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_participants', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', 0, 'STARTED')",
    post_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_participants', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', DATEDIFF('second', (SELECT MAX(load_timestamp) FROM {{ this.schema }}.bz_audit_log WHERE source_table = 'bz_participants' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
) }}

-- Bronze layer transformation for participants table
SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'participants') }}
