{{ config(
    materialized='table'
) }}

WITH date_spine AS (
    SELECT 
        DISTINCT CAST(start_time AS DATE) as date_key
    FROM SILVER.si_meetings
    WHERE start_time IS NOT NULL
    
    UNION
    
    SELECT 
        DISTINCT CAST(start_time AS DATE) as date_key
    FROM SILVER.si_webinars
    WHERE start_time IS NOT NULL
),

final AS (
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
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'SYSTEM' as source_system
    FROM date_spine
)

SELECT * FROM final
