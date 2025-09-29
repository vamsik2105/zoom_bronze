{% macro log_model_start(model_name) %}
  {% if execute and model_name != 'audit_log' %}
    {% set query %}
      INSERT INTO {{ ref('audit_log') }} (model_name, status, start_time, end_time, rows_affected, error_message)
      VALUES ('{{ model_name }}', 'started', CURRENT_TIMESTAMP(), NULL, NULL, NULL)
    {% endset %}
    {% do run_query(query) %}
  {% endif %}
  {{ return('') }}
{% endmacro %}

{% macro log_model_completion(model_name, rows_affected) %}
  {% if execute and model_name != 'audit_log' %}
    {% set query %}
      INSERT INTO {{ ref('audit_log') }} (model_name, status, start_time, end_time, rows_affected, error_message)
      VALUES ('{{ model_name }}', 'completed', NULL, CURRENT_TIMESTAMP(), {{ rows_affected }}, NULL)
    {% endset %}
    {% do run_query(query) %}
  {% endif %}
  {{ return('') }}
{% endmacro %}
