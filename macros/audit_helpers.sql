{% macro log_table_processing_start(table_name) %}
  INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
  SELECT
    '{{ table_name }}' AS source_table,
    CURRENT_TIMESTAMP() AS load_timestamp,
    CURRENT_USER() AS processed_by,
    'STARTED' AS status
  WHERE '{{ this.name }}' != 'bz_audit_log'
{% endmacro %}

{% macro log_table_processing_complete(table_name) %}
  INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
  SELECT
    '{{ table_name }}' AS source_table,
    CURRENT_TIMESTAMP() AS load_timestamp,
    CURRENT_USER() AS processed_by,
    DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = '{{ table_name }}' AND status = 'STARTED'), CURRENT_TIMESTAMP()) AS processing_time,
    'COMPLETED' AS status
  WHERE '{{ this.name }}' != 'bz_audit_log'
{% endmacro %}
