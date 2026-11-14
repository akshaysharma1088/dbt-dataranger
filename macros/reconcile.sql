{#
  Rows where a model disagrees with control totals: a day (or a day and segment) whose row count
  or summed amount differs, or that exists on one side only. No rows means the model reconciles.

  `expected_sql` must return the columns: dr_day, dr_segment, n, amount.
#}
{% macro reconcile(model, expected_sql, date_column, amount_column, segment_column=none,
                   amount_tolerance=0, count_tolerance=0, where=none) %}
    {%- set filter = ('where ' ~ where) if where else '' -%}
    with actual as (
        select
            cast({{ date_column }} as date) as dr_day,
            {% if segment_column -%}
            cast({{ segment_column }} as {{ dbt.type_string() }})
            {%- else -%}
            cast('*' as {{ dbt.type_string() }})
            {%- endif %} as dr_segment,
            count(*) as n,
            sum({{ amount_column }}) as amount
        from {{ model }}
        {{ filter }}
        group by 1, 2
    ),
    expected as (
        select dr_day, dr_segment, n, amount
        from ({{ expected_sql }}) totals
        where {% if segment_column %}dr_segment <> '*'{% else %}dr_segment = '*'{% endif %}
    )
    select
        coalesce(a.dr_day, e.dr_day) as day,
        coalesce(a.dr_segment, e.dr_segment) as segment,
        coalesce(a.n, 0) as rows_in_model,
        coalesce(e.n, 0) as rows_expected,
        coalesce(a.amount, 0) as amount_in_model,
        coalesce(e.amount, 0) as amount_expected
    from actual a
    full outer join expected e
        on a.dr_day = e.dr_day and a.dr_segment = e.dr_segment
    where a.dr_day is null
       or e.dr_day is null
       or abs(a.n - e.n) > {{ count_tolerance }} * e.n
       or abs(coalesce(a.amount, 0) - coalesce(e.amount, 0)) > {{ amount_tolerance }} * abs(coalesce(e.amount, 0))
{% endmacro %}
