-- Simple test model to verify DBT setup
{{ config(
    materialized='table'
) }}

SELECT 
    'test' as test_column,
    CURRENT_TIMESTAMP() as created_at,
    'Zoom_Customer_Analytics' as project_name
