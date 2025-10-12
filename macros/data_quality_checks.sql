{% macro calculate_data_quality_score(table_name, record_id) %}
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM {{ ref('si_data_quality_errors') }} 
      WHERE source_table = '{{ table_name }}' 
      AND record_identifier = {{ record_id }}
      AND severity_level = 'High'
    ) THEN 0.0
    WHEN EXISTS (
      SELECT 1 FROM {{ ref('si_data_quality_errors') }} 
      WHERE source_table = '{{ table_name }}' 
      AND record_identifier = {{ record_id }}
      AND severity_level = 'Medium'
    ) THEN 0.5
    WHEN EXISTS (
      SELECT 1 FROM {{ ref('si_data_quality_errors') }} 
      WHERE source_table = '{{ table_name }}' 
      AND record_identifier = {{ record_id }}
      AND severity_level = 'Low'
    ) THEN 0.8
    ELSE 1.0
  END
{% endmacro %}

{% macro log_audit_start(model_name) %}
  INSERT INTO {{ ref('si_process_audit') }} (
    execution_id,
    pipeline_name,
    start_time,
    status,
    records_processed,
    records_successful,
    records_failed,
    processing_duration_seconds,
    source_system,
    target_system,
    process_type,
    load_date,
    update_date
  )
  SELECT 
    '{{ invocation_id }}' || '_{{ model_name }}',
    '{{ model_name }}',
    CURRENT_TIMESTAMP,
    'RUNNING',
    0,
    0,
    0,
    0,
    'BRONZE',
    'SILVER',
    'ETL',
    CURRENT_DATE,
    CURRENT_DATE
  WHERE '{{ this.name }}' != 'si_process_audit'
{% endmacro %}

{% macro log_audit_end(model_name) %}
  UPDATE {{ ref('si_process_audit') }}
  SET 
    end_time = CURRENT_TIMESTAMP,
    status = 'SUCCESS',
    processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP),
    update_date = CURRENT_DATE
  WHERE execution_id = '{{ invocation_id }}' || '_{{ model_name }}'
  AND '{{ this.name }}' != 'si_process_audit'
{% endmacro %}
