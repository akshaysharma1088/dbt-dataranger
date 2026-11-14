{#
  Fails when the model's rows or amounts, per day (and per segment when given), do not match a
  control totals table laid out as: date, segment ('*' = whole day), n, amount.
  That is the layout dataranger.control_totals() produces and DataRanger reads.
#}
{% test matches_control_totals(model, totals, date_column, amount_column, segment_column=none,
                               totals_date_column=none, totals_segment_column=none,
                               amount_tolerance=0, count_tolerance=0, where=none) %}
    {%- set t_date = totals_date_column or date_column -%}
    {%- set t_segment = totals_segment_column or segment_column or 'segment' -%}
    {%- set expected_sql -%}
        select cast({{ t_date }} as date) as dr_day,
               cast({{ t_segment }} as {{ dbt.type_string() }}) as dr_segment,
               n, amount
        from {{ totals }}
    {%- endset -%}
    {{ dataranger.reconcile(model, expected_sql, date_column, amount_column, segment_column,
                            amount_tolerance, count_tolerance, where) }}
{% endtest %}


{#
  Fails when the model's rows or amounts, per day (and per segment when given), do not match the
  raw table it was built from. Catches a join that fans out, a filter that drops too much, a
  late or partial load and a unit change, all of which pass not_null and unique.
#}
{% test reconciles_with_source(model, source_relation, date_column, amount_column, segment_column=none,
                               source_date_column=none, source_amount_column=none, source_segment_column=none,
                               source_where=none, amount_tolerance=0, count_tolerance=0, where=none) %}
    {%- set expected_sql = dataranger.control_totals(
            source_relation,
            source_date_column or date_column,
            source_amount_column or amount_column,
            segment_column=(source_segment_column or segment_column) if segment_column else none,
            where=source_where, date_alias='dr_day', segment_alias='dr_segment') -%}
    {{ dataranger.reconcile(model, expected_sql, date_column, amount_column, segment_column,
                            amount_tolerance, count_tolerance, where) }}
{% endtest %}
