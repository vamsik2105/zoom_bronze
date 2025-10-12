{{
  config(
    materialized='table',
    pre_hook="""
      {% if this.name != 'sv_audit_log' %}
        INSERT INTO {{ ref('sv_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
        VALUES ('{{ this.name }}', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED')
      {% endif %}
    """,
    post_hook="""
      {% if this.name != 'sv_audit_log' %}
        INSERT INTO {{ ref('sv_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
        VALUES ('{{ this.name }}', CURRENT_TIMESTAMP(), 'dbt_transformation', 1, 'COMPLETED')
      {% endif %}
    """
  )
}}

-- Transform bronze billing events to silver layer with data quality checks
WITH bronze_billing_events AS (
    SELECT *
    FROM {{ source('bronze', 'bz_billing_events') }}
),

-- Data Quality Validation
validated_billing_events AS (
    SELECT 
        *,
        -- Data Quality Checks
        CASE 
            WHEN event_id IS NULL OR TRIM(event_id) = '' THEN 'INVALID_EVENT_ID'
            WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 'INVALID_USER_ID'
            WHEN event_type IS NULL OR TRIM(event_type) = '' THEN 'INVALID_EVENT_TYPE'
            WHEN event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 'INVALID_EVENT_TYPE_VALUE'
            WHEN amount IS NULL OR amount < 0 THEN 'INVALID_AMOUNT'
            WHEN event_date IS NULL THEN 'INVALID_EVENT_DATE'
            WHEN source_system IS NULL OR TRIM(source_system) = '' THEN 'INVALID_SOURCE_SYSTEM'
            ELSE 'VALID'
        END as validation_status
    FROM bronze_billing_events
),

-- Valid Records for Silver Layer
valid_records AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION FEE' THEN 'Subscription Fee'
            WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION RENEWAL' THEN 'Subscription Renewal'
            WHEN UPPER(TRIM(event_type)) = 'ADD-ON PURCHASE' THEN 'Add-on Purchase'
            WHEN UPPER(TRIM(event_type)) = 'REFUND' THEN 'Refund'
            ELSE event_type
        END as event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        1.0 as data_quality_score,
        'active' as record_status
    FROM validated_billing_events
    WHERE validation_status = 'VALID'
)

SELECT * FROM valid_records
