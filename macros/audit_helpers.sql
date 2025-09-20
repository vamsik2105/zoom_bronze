{% macro add_audit_columns() %}
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS updated_at,
    CURRENT_USER() AS processed_by,
    '{{ this.schema }}.{{ this.name }}' AS target_table_name
{% endmacro %}

-- Macro for data quality status determination
{% macro determine_process_status(conditions) %}
    CASE 
        {% for condition in conditions %}
        WHEN {{ condition.condition }} THEN '{{ condition.status }}'
        {% endfor %}
        ELSE 'SUCCESS'
    END
{% endmacro %}

-- Macro for safe column mapping with null handling
{% macro safe_column_map(source_column, target_column, default_value='NULL', transformation='NONE') %}
    {% if transformation == 'UPPER' %}
        COALESCE(UPPER(TRIM({{ source_column }})), {{ default_value }}) AS {{ target_column }}
    {% elif transformation == 'LOWER' %}
        COALESCE(LOWER(TRIM({{ source_column }})), {{ default_value }}) AS {{ target_column }}
    {% elif transformation == 'TRIM' %}
        COALESCE(TRIM({{ source_column }}), {{ default_value }}) AS {{ target_column }}
    {% else %}
        COALESCE({{ source_column }}, {{ default_value }}) AS {{ target_column }}
    {% endif %}
{% endmacro %}