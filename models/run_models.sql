-- This file is used to trigger a run of all models
{{ config(materialized='ephemeral') }}

SELECT 1 as dummy
