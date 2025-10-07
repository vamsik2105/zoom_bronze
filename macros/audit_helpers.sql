{% macro log_audit_start(model_name) %}
  {% if execute and model_name != 'bz_audit_log' %}
    {% set audit_query %}
      INSERT INTO {{ target.schema }}.bz_audit_log (record_id, source_table, load_timestamp, processed_by, processing_time, status)
      SELECT 
        (SELECT COALESCE(MAX(record_id), 0) + 1 FROM {{ target.schema }}.bz_audit_log),
        '{{ model_name }}',
        CURRENT_TIMESTAMP(),
        CURRENT_USER(),
        0,
        'STARTED'
    {% endset %}
    {% do run_query(audit_query) %}
  {% endif %}
{% endmacro %}

{% macro log_audit_end(model_name, success) %}
  {% if execute and model_name != 'bz_audit_log' %}
    {% set status = 'SUCCESS' if success else 'FAILED' %}
    {% set audit_query %}
      INSERT INTO {{ target.schema }}.bz_audit_log (record_id, source_table, load_timestamp, processed_by, processing_time, status)
      SELECT 
        (SELECT COALESCE(MAX(record_id), 0) + 1 FROM {{ target.schema }}.bz_audit_log),
        '{{ model_name }}',
        CURRENT_TIMESTAMP(),
        CURRENT_USER(),
        0,
        '{{ status }}'
    {% endset %}
    {% do run_query(audit_query) %}
  {% endif %}
{% endmacro %}
