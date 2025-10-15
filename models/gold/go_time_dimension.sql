{{ config(
    materialized='table'
) }}

-- Gold Time Dimension Table
-- Creates comprehensive time dimension from Silver meeting data

WITH silver_meetings AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) as date_key,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver', 'si_meetings') }}
    WHERE start_time IS NOT NULL
      AND record_status = 'ACTIVE'
),

silver_webinars AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) as date_key,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver', 'si_webinars') }}
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
        FALSE as is_holiday,  -- Not available in Silver
        EXTRACT(YEAR FROM date_key) as fiscal_year,
        EXTRACT(QUARTER FROM date_key) as fiscal_quarter,
        load_date,
        update_date,
        source_system,
        CURRENT_TIMESTAMP() as created_at,
        CURRENT_TIMESTAMP() as updated_at,
        'SUCCESS' as process_status
    FROM all_dates
)

SELECT * FROM time_dimension
