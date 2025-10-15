{{ config(
    materialized='table',
    pre_hook="INSERT INTO GOLD.go_process_audit (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) VALUES ('{{ invocation_id }}', 'go_time_dimension', 'TRANSFORMATION', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE())",
    post_hook="UPDATE GOLD.go_process_audit SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM GOLD.go_time_dimension), processing_duration_seconds = 10 WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_time_dimension'"
) }}

-- Gold Time Dimension Table
-- Creates comprehensive time dimension from Silver meeting data

WITH silver_meetings AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) as date_key,
        source_system,
        load_date,
        update_date
    FROM SILVER.si_meetings
    WHERE start_time IS NOT NULL
      AND record_status = 'ACTIVE'
),

silver_webinars AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) as date_key,
        source_system,
        load_date,
        update_date
    FROM SILVER.si_webinars
    WHERE start_time IS NOT NULL
      AND record_status = 'ACTIVE'
),

all_dates AS (
    SELECT date_key, source_system, load_date, update_date FROM silver_meetings
    UNION
    SELECT date_key, source_system, load_date, update_date FROM silver_webinars
),

time_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['date_key']) }} as time_dim_id,
        date_key,
        EXTRACT(YEAR FROM date_key) as year_number,
        EXTRACT(QUARTER FROM date_key) as quarter_number,
        EXTRACT(MONTH FROM date_key) as month_number,
        TO_VARCHAR(date_key, 'MMMM') as month_name,
        EXTRACT(WEEK FROM date_key) as week_number,
        EXTRACT(DOY FROM date_key) as day_of_year,
        EXTRACT(DAY FROM date_key) as day_of_month,
        EXTRACT(DOW FROM date_key) as day_of_week,
        TO_VARCHAR(date_key, 'DAY') as day_name,
        CASE WHEN EXTRACT(DOW FROM date_key) IN (0,6) THEN TRUE ELSE FALSE END as is_weekend,
        FALSE as is_holiday,
        EXTRACT(YEAR FROM date_key) as fiscal_year,
        EXTRACT(QUARTER FROM date_key) as fiscal_quarter,
        load_date,
        update_date,
        source_system
    FROM all_dates
)

SELECT * FROM time_dimension
