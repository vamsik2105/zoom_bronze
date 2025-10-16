{{ config(
    materialized='table'
) }}

WITH meeting_dates AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) as date_key,
        start_time,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver', 'si_meetings') }}
    WHERE start_time IS NOT NULL
    AND record_status = 'ACTIVE'
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['date_key']) }} as time_dim_id,
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
