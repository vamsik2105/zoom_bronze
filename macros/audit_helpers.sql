{% macro log_model_start(model_name) %}
    {% set query %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message
        )
        SELECT
            '{{ model_name }}',
            CURRENT_TIMESTAMP(),
            'STARTED',
            'Processing started for {{ model_name }}'
    {% endset %}
    
    {% do run_query(query) %}
{% endmacro %}

{% macro log_model_completion(model_name, row_count) %}
    {% set query %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message,
            row_count
        )
        SELECT
            '{{ model_name }}',
            CURRENT_TIMESTAMP(),
            'COMPLETED',
            'Processing completed for {{ model_name }}',
            {{ row_count }}
    {% endset %}
    
    {% do run_query(query) %}
{% endmacro %}

{% macro log_model_error(model_name, error_message) %}
    {% set query %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message
        )
        SELECT
            '{{ model_name }}',
            CURRENT_TIMESTAMP(),
            'ERROR',
            '{{ error_message }}'
    {% endset %}
    
    {% do run_query(query) %}
{% endmacro %}
