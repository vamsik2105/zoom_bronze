{{
  config(
    materialized='table'
  )
}}

-- Time Dimension transformation from Silver meetings data
WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    )}}
),

time_dimension_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['date_day']) }} AS time_dim_id,
        date_day AS date_key,
        EXTRACT(YEAR FROM date_day) AS year_number,
        EXTRACT(QUARTER FROM date_day) AS quarter_number,
        EXTRACT(MONTH FROM date_day) AS month_number,
        TO_VARCHAR(date_day, 'MMMM') AS month_name,
        EXTRACT(WEEK FROM date_day) AS week_number,
        EXTRACT(DOY FROM date_day) AS day_of_year,
        EXTRACT(DAY FROM date_day) AS day_of_month,
        EXTRACT(DOW FROM date_day) AS day_of_week,
        TO_VARCHAR(date_day, 'DAY') AS day_name,
        CASE WHEN EXTRACT(DOW FROM date_day) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,
        FALSE AS is_holiday,
        EXTRACT(YEAR FROM date_day) AS fiscal_year,
        EXTRACT(QUARTER FROM date_day) AS fiscal_quarter,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'SYSTEM_GENERATED' AS source_system
    FROM date_spine
)

SELECT * FROM time_dimension_final
