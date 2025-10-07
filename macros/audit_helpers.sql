{% macro log_table_process_start(model_name) %}
{% if model_name != 'bz_audit_log' %}
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
    SELECT '{{ model_name }}', CURRENT_TIMESTAMP(), '{{ invocation_id }}', 'STARTED';
{% endif %}
{% endmacro %}

{% macro log_table_process_end(model_name, start_time) %}
{% if model_name != 'bz_audit_log' %}
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
    SELECT 
        '{{ model_name }}',
        CURRENT_TIMESTAMP(),
        '{{ invocation_id }}',
        DATEDIFF('MILLISECOND', {{ start_time }}, CURRENT_TIMESTAMP()) / 1000.0,
        'COMPLETED';
{% endif %}
{% endmacro %}
