{% macro log_audit_event(table_name, status, record_count=0) %}
  {% if execute %}
    {% set audit_query %}
      INSERT INTO {{ ref('audit_log') }} 
      (table_name, process_status, process_start_time, process_end_time, record_count, created_at)
      VALUES (
        '{{ table_name }}', 
        '{{ status }}', 
        {% if status == 'STARTED' %}CURRENT_TIMESTAMP{% else %}NULL{% endif %},
        {% if status == 'COMPLETED' %}CURRENT_TIMESTAMP{% else %}NULL{% endif %},
        {{ record_count }},
        CURRENT_TIMESTAMP
      )
    {% endset %}
    
    {% do run_query(audit_query) %}
  {% endif %}
{% endmacro %}

{% macro get_audit_columns() %}
  CURRENT_TIMESTAMP AS created_at,
  CURRENT_TIMESTAMP AS updated_at,
  'ACTIVE' AS process_status
{% endmacro %}

{% macro validate_email(email_column) %}
  CASE 
    WHEN {{ email_column }} IS NOT NULL 
         AND {{ email_column }} != '' 
         AND {{ email_column }} LIKE '%@%.%'
    THEN LOWER(TRIM({{ email_column }}))
    ELSE NULL 
  END
{% endmacro %}
