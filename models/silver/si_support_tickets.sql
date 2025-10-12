-- Silver Support Tickets Table - Cleaned and validated support ticket data

{{ config(
    materialized='table',
    unique_key='ticket_id'
) }}

WITH bronze_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('bronze', 'bz_support_tickets') }}
),

validated_support_tickets AS (
    SELECT 
        *,
        CASE 
            WHEN ticket_id IS NULL THEN 'NULL_TICKET_ID'
            WHEN user_id IS NULL THEN 'NULL_USER_ID'
            WHEN ticket_type IS NULL THEN 'NULL_TICKET_TYPE'
            WHEN ticket_type NOT IN ('Audio Issue', 'Video Issue', 'Connectivity', 'Billing Inquiry', 'Feature Request', 'Account Access') THEN 'INVALID_TICKET_TYPE'
            WHEN resolution_status IS NULL THEN 'NULL_RESOLUTION_STATUS'
            WHEN resolution_status NOT IN ('Open', 'In Progress', 'Pending Customer', 'Closed', 'Resolved') THEN 'INVALID_RESOLUTION_STATUS'
            WHEN open_date IS NULL THEN 'NULL_OPEN_DATE'
            WHEN source_system IS NULL THEN 'NULL_SOURCE_SYSTEM'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_support_tickets
),

transformed_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(ticket_type)) = 'AUDIO ISSUE' THEN 'Audio Issue'
            WHEN UPPER(TRIM(ticket_type)) = 'VIDEO ISSUE' THEN 'Video Issue'
            WHEN UPPER(TRIM(ticket_type)) = 'CONNECTIVITY' THEN 'Connectivity'
            WHEN UPPER(TRIM(ticket_type)) = 'BILLING INQUIRY' THEN 'Billing Inquiry'
            WHEN UPPER(TRIM(ticket_type)) = 'FEATURE REQUEST' THEN 'Feature Request'
            WHEN UPPER(TRIM(ticket_type)) = 'ACCOUNT ACCESS' THEN 'Account Access'
            ELSE ticket_type
        END AS ticket_type,
        CASE 
            WHEN UPPER(TRIM(resolution_status)) = 'OPEN' THEN 'Open'
            WHEN UPPER(TRIM(resolution_status)) = 'IN PROGRESS' THEN 'In Progress'
            WHEN UPPER(TRIM(resolution_status)) = 'PENDING CUSTOMER' THEN 'Pending Customer'
            WHEN UPPER(TRIM(resolution_status)) = 'CLOSED' THEN 'Closed'
            WHEN UPPER(TRIM(resolution_status)) = 'RESOLVED' THEN 'Resolved'
            ELSE resolution_status
        END AS resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        {{ calculate_data_quality_score('si_support_tickets', 'ticket_id') }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status,
        validation_status
    FROM validated_support_tickets
)

SELECT 
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM transformed_support_tickets
WHERE validation_status = 'VALID'

UNION ALL

SELECT 
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    0.0 AS data_quality_score,
    'error' AS record_status
FROM transformed_support_tickets
WHERE validation_status != 'VALID'
