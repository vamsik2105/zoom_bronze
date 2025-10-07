{% macro log_audit_start(model_name) %}
  {% if execute and model_name != 'bz_audit_log' %}
    {% set query %}
      INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, status)
      SELECT 
        '{{ model_name }}',
        CURRENT_TIMESTAMP(),
        'DBT',
        'STARTED'
    {% endset %}
    {% do run_query(query) %}
  {% endif %}
{% endmacro %}

{% macro log_audit_end(model_name) %}
  {% if execute and model_name != 'bz_audit_log' %}
    {% set query %}
      INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status)
      SELECT 
        '{{ model_name }}',
        CURRENT_TIMESTAMP(),
        'DBT',
        DATEDIFF('SECOND', (SELECT MAX(load_timestamp) FROM {{ target.schema }}.bz_audit_log WHERE source_table = '{{ model_name }}' AND status = 'STARTED'), CURRENT_TIMESTAMP()),
        'COMPLETED'
    {% endset %}
    {% do run_query(query) %}
  {% endif %}
{% endmacro %}
