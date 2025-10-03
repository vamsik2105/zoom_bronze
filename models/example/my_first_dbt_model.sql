-- Simple test model

/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml
*/

{{ config(materialized='table') }}

SELECT 1 as id
