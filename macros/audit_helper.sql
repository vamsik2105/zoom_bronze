{% macro log_audit_start(source_table) %}
  INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
  SELECT 
    '{{ source_table }}',
    CURRENT_TIMESTAMP(),
    CURRENT_USER(),
    0,
    'PROCESSING'
  {% if target.table != 'bz_audit_log' %}
  {% endif %}
{% endmacro %}

{% macro log_audit_end(source_table, status) %}
  INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
  SELECT 
    '{{ source_table }}',
    CURRENT_TIMESTAMP(),
    CURRENT_USER(),
    DATEDIFF('SECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = '{{ source_table }}' AND status = 'PROCESSING'), CURRENT_TIMESTAMP()),
    '{{ status }}'
  {% if target.table != 'bz_audit_log' %}
  {% endif %}
{% endmacro %}
