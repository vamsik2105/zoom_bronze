{% macro log_audit_start() %}
  {% if execute %}
    INSERT INTO {{ target.schema }}.bz_audit_log (
      source_table,
      load_timestamp,
      processed_by,
      processing_time,
      status
    )
    VALUES (
      '{{ this.identifier }}',
      CURRENT_TIMESTAMP(),
      '{{ target.user }}',
      0,
      'STARTED'
    )
  {% endif %}
{% endmacro %}

{% macro log_audit_end() %}
  {% if execute %}
    UPDATE {{ target.schema }}.bz_audit_log 
    SET 
      processing_time = DATEDIFF('second', load_timestamp, CURRENT_TIMESTAMP()),
      status = 'COMPLETED'
    WHERE source_table = '{{ this.identifier }}'
      AND status = 'STARTED'
      AND load_timestamp = (
        SELECT MAX(load_timestamp) 
        FROM {{ target.schema }}.bz_audit_log 
        WHERE source_table = '{{ this.identifier }}' 
          AND status = 'STARTED'
      )
  {% endif %}
{% endmacro %}
