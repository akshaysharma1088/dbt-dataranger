{#
  Control totals for a table: one row per day and segment, plus a '*' row for the whole day,
  each with the row count (n) and the summed amount.

  Build them from the raw or landing table your fact table is loaded from. They are what
  DataRanger and the tests in this package compare a fact table against.

  Arguments
    relation        the raw table, for example source('erp', 'payments') or ref('stg_payments')
    date_column     the date (or timestamp) column in that table
    amount_column   the numeric column to total
    segment_column  optional column to break the day down by (channel, region, currency)
    where           optional SQL filter for the rows that should reach the fact table
    date_alias      name of the date column in the result (default: date_column)
    segment_alias   name of the segment column in the result (default: segment_column, or "segment")
#}
{% macro control_totals(relation, date_column, amount_column, segment_column=none, where=none,
                        date_alias=none, segment_alias=none) %}
    {%- set date_alias = date_alias or date_column -%}
    {%- set segment_alias = segment_alias or segment_column or 'segment' -%}
    {%- set filter = ('where ' ~ where) if where else '' -%}
    {%- if segment_column %}
    select
        cast({{ date_column }} as date) as {{ date_alias }},
        cast({{ segment_column }} as {{ dbt.type_string() }}) as {{ segment_alias }},
        count(*) as n,
        sum({{ amount_column }}) as amount
    from {{ relation }}
    {{ filter }}
    group by 1, 2
    union all
    {%- endif %}
    select
        cast({{ date_column }} as date) as {{ date_alias }},
        cast('*' as {{ dbt.type_string() }}) as {{ segment_alias }},
        count(*) as n,
        sum({{ amount_column }}) as amount
    from {{ relation }}
    {{ filter }}
    group by 1
{% endmacro %}
