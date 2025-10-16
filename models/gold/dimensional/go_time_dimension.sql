{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, created_at, updated_at) VALUES (UUID_STRING(), 'time_dimension_transformation', 'si_meetings', 'go_time_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}), updated_at = CURRENT_TIMESTAMP() WHERE process_name = 'time_dimension_transformation' AND process_status = 'STARTED'"
) }}

WITH meeting_dates AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) as date_key,
        start_time,
        load_date,
        update_date,
        source_system
    FROM {{ ref('si_meetings') }}
    WHERE start_time IS NOT NULL
    AND record_status = 'ACTIVE'
)

SELECT 
    UUID_STRING() as time_dim_id,
    date_key,
    EXTRACT(YEAR FROM start_time) as year_number,
    EXTRACT(QUARTER FROM start_time) as quarter_number,
    EXTRACT(MONTH FROM start_time) as month_number,
    TO_VARCHAR(start_time, 'MMMM') as month_name,
    EXTRACT(WEEK FROM start_time) as week_number,
    EXTRACT(DOY FROM start_time) as day_of_year,
    EXTRACT(DAY FROM start_time) as day_of_month,
    EXTRACT(DOW FROM start_time) as day_of_week,
    TO_VARCHAR(start_time, 'DAY') as day_name,
    CASE WHEN EXTRACT(DOW FROM start_time) IN (0,6) THEN TRUE ELSE FALSE END as is_weekend,
    FALSE as is_holiday,
    EXTRACT(YEAR FROM start_time) as fiscal_year,
    EXTRACT(QUARTER FROM start_time) as fiscal_quarter,
    load_date,
    update_date,
    source_system,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    'ACTIVE' as process_status
FROM meeting_dates
