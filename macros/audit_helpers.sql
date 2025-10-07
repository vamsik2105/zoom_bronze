{% macro create_audit_table_if_not_exists() %}
  {% set create_audit_table_query %}
    CREATE TABLE IF NOT EXISTS {{ target.schema }}.bz_audit_log (
      record_id NUMBER AUTOINCREMENT,
      source_table STRING,
      load_timestamp TIMESTAMP_NTZ,
      processed_by STRING,
      processing_time NUMBER,
      status STRING
    )
  {% endset %}
  
  {% do run_query(create_audit_table_query) %}
{% endmacro %}

{% macro log_audit_start(model_name) %}
  {{ create_audit_table_if_not_exists() }}
  
  {% set audit_insert_query %}
    INSERT INTO {{ target.schema }}.bz_audit_log (
      source_table, 
      load_timestamp, 
      processed_by, 
      status
    )
    SELECT 
      '{{ model_name }}',
      CURRENT_TIMESTAMP(),
      'DBT',
      'STARTED'
  {% endset %}
  
  {% do run_query(audit_insert_query) %}
{% endmacro %}

{% macro log_audit_end(model_name) %}
  {% set audit_end_query %}
    INSERT INTO {{ target.schema }}.bz_audit_log (
      source_table, 
      load_timestamp, 
      processed_by, 
      processing_time, 
      status
    )
    SELECT 
      '{{ model_name }}',
      CURRENT_TIMESTAMP(),
      'DBT',
      DATEDIFF('SECOND', (
        SELECT MAX(load_timestamp) 
        FROM {{ target.schema }}.bz_audit_log 
        WHERE source_table = '{{ model_name }}' AND status = 'STARTED'
      ), CURRENT_TIMESTAMP()),
      'COMPLETED'
  {% endset %}
  
  {% do run_query(audit_end_query) %}
{% endmacro %}

{% macro handle_error(model_name, error_message) %}
  {% set error_query %}
    INSERT INTO {{ target.schema }}.bz_audit_log (
      source_table, 
      load_timestamp, 
      processed_by, 
      status
    )
    SELECT 
      '{{ model_name }}',
      CURRENT_TIMESTAMP(),
      'DBT',
      'ERROR: {{ error_message }}'
  {% endset %}
  
  {% do run_query(error_query) %}
{% endmacro %}
