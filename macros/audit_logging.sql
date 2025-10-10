-- Macro to create audit log table
{% macro create_audit_log_table() %}
  {% set audit_table_sql %}
    CREATE TABLE IF NOT EXISTS {{ target.database }}.{{ target.schema }}.bz_audit_log (
      record_id NUMBER AUTOINCREMENT,
      source_table VARCHAR(255),
      load_timestamp TIMESTAMP_NTZ,
      processed_by STRING,
      processing_time NUMBER,
      status STRING
    )
  {% endset %}
  
  {% do run_query(audit_table_sql) %}
{% endmacro %}

-- Macro for pre-hook audit logging
{% macro log_audit_start() %}
  {{ create_audit_log_table() }}
  
  {% set audit_start_sql %}
    INSERT INTO {{ target.database }}.{{ target.schema }}.bz_audit_log 
    (source_table, load_timestamp, processed_by, status)
    VALUES ('{{ this.name }}', CURRENT_TIMESTAMP(), '{{ target.user }}', 'STARTED')
  {% endset %}
  
  {{ audit_start_sql }}
{% endmacro %}

-- Macro for post-hook audit logging
{% macro log_audit_end() %}
  {% set audit_end_sql %}
    INSERT INTO {{ target.database }}.{{ target.schema }}.bz_audit_log 
    (source_table, load_timestamp, processed_by, processing_time, status)
    VALUES ('{{ this.name }}', CURRENT_TIMESTAMP(), '{{ target.user }}', 
            DATEDIFF('seconds', 
              (SELECT MAX(load_timestamp) FROM {{ target.database }}.{{ target.schema }}.bz_audit_log 
               WHERE source_table = '{{ this.name }}' AND status = 'STARTED'), 
              CURRENT_TIMESTAMP()), 'COMPLETED')
  {% endset %}
  
  {{ audit_end_sql }}
{% endmacro %}
