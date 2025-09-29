{{config(
  materialized = 'incremental',
  unique_key = 'audit_id'
)}}

WITH audit_data AS (
  SELECT
    MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', '{{ this.name }}')) as audit_id,
    '{{ this.name }}' as model_name,
    CURRENT_TIMESTAMP() as process_timestamp,
    'START' as process_status,
    NULL as error_message,
    NULL as record_count
)

SELECT
  audit_id,
  model_name,
  process_timestamp,
  process_status,
  error_message,
  record_count
FROM audit_data

{% if is_incremental() %}
WHERE audit_id NOT IN (SELECT audit_id FROM {{ this }})
{% endif %}
