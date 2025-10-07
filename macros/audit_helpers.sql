{% macro log_audit_start(model_name) %}
  {% if execute and model_name != 'bz_audit_log' %}
    {% set audit_query %}
      INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status)
      SELECT 
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
      INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status)
      SELECT 
        '{{ model_name }}',
        CURRENT_TIMESTAMP(),
        CURRENT_USER(),
        DATEDIFF('SECOND', (SELECT MAX(load_timestamp) FROM {{ target.schema }}.bz_audit_log WHERE source_table = '{{ model_name }}' AND status = 'STARTED'), CURRENT_TIMESTAMP()),
        '{{ status }}'
    {% endset %}
    {% do run_query(audit_query) %}
  {% endif %}
{% endmacro %}
