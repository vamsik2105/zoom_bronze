{% macro log_audit_start(source_table) %}
  INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
  VALUES ('{{ source_table }}', CURRENT_TIMESTAMP(), CURRENT_USER(), 'STARTED')
{% endmacro %}

{% macro log_audit_end(source_table) %}
  INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
  VALUES (
    '{{ source_table }}', 
    CURRENT_TIMESTAMP(), 
    CURRENT_USER(), 
    DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = '{{ source_table }}' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 
    'COMPLETED'
  )
{% endmacro %}
