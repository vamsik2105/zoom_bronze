{% macro calculate_data_quality_score(required_fields, optional_fields=[]) %}
  CASE 
    {% for field in required_fields %}
    WHEN {{ field }} IS NULL THEN 0.0
    {% endfor %}
    {% if required_fields|length > 0 and optional_fields|length > 0 %}
    WHEN {% for field in required_fields %}{{ field }} IS NOT NULL{% if not loop.last %} AND {% endif %}{% endfor %}
         AND {% for field in optional_fields %}{{ field }} IS NOT NULL{% if not loop.last %} AND {% endif %}{% endfor %}
    THEN 1.0
    {% endif %}
    {% if required_fields|length > 0 %}
    WHEN {% for field in required_fields %}{{ field }} IS NOT NULL{% if not loop.last %} AND {% endif %}{% endfor %}
    THEN {{ 0.5 + (0.5 * optional_fields|length / (optional_fields|length + 1)) if optional_fields|length > 0 else 0.75 }}
    {% endif %}
    ELSE 0.0
  END
{% endmacro %}

{% macro log_data_quality_error(source_table, source_column, error_type, error_value, expected_format, record_id) %}
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
  VALUES (
    {{ dbt_utils.generate_surrogate_key(["'" + source_table + "'", "'" + error_type + "'", 'CURRENT_TIMESTAMP()']) }},
    '{{ source_table }}',
    '{{ source_column }}',
    '{{ error_type }}',
    'Data quality validation failed for {{ source_column }} in {{ source_table }}',
    '{{ error_value }}',
    '{{ expected_format }}',
    '{{ record_id }}',
    CURRENT_TIMESTAMP(),
    'MEDIUM',
    'OPEN',
    CURRENT_DATE(),
    CURRENT_DATE(),
    'dbt_system'
  )
{% endmacro %}
