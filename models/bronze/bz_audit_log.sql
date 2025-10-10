{{ config(
    materialized='table',
    pre_hook=none,
    post_hook=none
) }}

CREATE TABLE IF NOT EXISTS {{ this }} (
    record_id NUMBER AUTOINCREMENT,
    source_table VARCHAR(255),
    load_timestamp TIMESTAMP_NTZ,
    processed_by STRING,
    processing_time NUMBER,
    status STRING
)
