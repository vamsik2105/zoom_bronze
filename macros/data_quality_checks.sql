{% macro calculate_data_quality_score(completeness_status, format_status, logic_status='VALID_LOGIC') %}
  CASE 
    WHEN '{{ completeness_status }}' != 'VALID' OR '{{ format_status }}' != 'VALID_FORMAT' OR '{{ logic_status }}' != 'VALID_LOGIC' THEN 0.0
    ELSE 1.0
  END
{% endmacro %}

{% macro log_data_quality_error(source_table, error_type, error_description, record_identifier) %}
  INSERT INTO {{ ref('si_data_quality_errors') }} (
    error_id,
    source_table,
    source_column,
    error_type,
    error_description,
    error_value,
    expected_format,
    record_identifier,
    error_timestamp,
    severity_level,
    resolution_status,
    load_date,
    update_date,
    source_system
  )
  SELECT 
    UUID_STRING() as error_id,
    '{{ source_table }}' as source_table,
    'MULTIPLE' as source_column,
    '{{ error_type }}' as error_type,
    '{{ error_description }}' as error_description,
    'N/A' as error_value,
    'Valid format required' as expected_format,
    '{{ record_identifier }}' as record_identifier,
    CURRENT_TIMESTAMP() as error_timestamp,
    'HIGH' as severity_level,
    'OPEN' as resolution_status,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'BRONZE' as source_system
{% endmacro %}
