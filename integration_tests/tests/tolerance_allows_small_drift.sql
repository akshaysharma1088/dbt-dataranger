-- A 100x change is far outside a 1% tolerance but inside a 10000% one.
with failures as (
    {{ dataranger.test_matches_control_totals(
        model=ref('fct_payments_cents'), totals=ref('source_totals'),
        date_column='paid_on', amount_column='amount', totals_segment_column='channel', amount_tolerance=100) }}
)
select 'tolerance was ignored' as problem
where (select count(*) from failures) <> 0
