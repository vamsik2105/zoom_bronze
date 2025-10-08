{% macro log_audit_start(model_name) %}
  {% if model_name != 'bz_audit_log' %}
    INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status)
    SELECT 
      '{{ model_name }}',
      CURRENT_TIMESTAMP(),
      'dbt',
      0,
      'started'
  {% endif %}
{% endmacro %}

{% macro log_audit_end(model_name) %}
  {% if model_name != 'bz_audit_log' %}
    INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status)
    SELECT 
      '{{ model_name }}',
      CURRENT_TIMESTAMP(),
      'dbt',
      DATEDIFF('SECOND', (SELECT MAX(load_timestamp) FROM {{ target.schema }}.bz_audit_log WHERE source_table = '{{ model_name }}' AND status = 'started'), CURRENT_TIMESTAMP()),
      'completed'
  {% endif %}
{% endmacro %}

{% macro log_audit_error(model_name) %}
  {% if model_name != 'bz_audit_log' %}
    INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status)
    SELECT 
      '{{ model_name }}',
      CURRENT_TIMESTAMP(),
      'dbt',
      DATEDIFF('SECOND', (SELECT MAX(load_timestamp) FROM {{ target.schema }}.bz_audit_log WHERE source_table = '{{ model_name }}' AND status = 'started'), CURRENT_TIMESTAMP()),
      'error'
  {% endif %}
{% endmacro %}
