{{ config(
    materialized='table'
) }}

SELECT 
    'TIME_001' AS time_dim_id,
    '2024-01-01'::date AS date_key,
    2024 AS year_number,
    1 AS quarter_number,
    1 AS month_number,
    'January' AS month_name,
    1 AS week_number,
    1 AS day_of_year,
    1 AS day_of_month,
    1 AS day_of_week,
    'Monday' AS day_name,
    FALSE AS is_weekend,
    FALSE AS is_holiday,
    2024 AS fiscal_year,
    1 AS fiscal_quarter,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'SYSTEM_GENERATED' AS source_system
