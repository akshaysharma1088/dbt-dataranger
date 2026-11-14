-- Only 2026-11-04 changed units, so exactly that day must be reported, for every channel.
with failures as (
    {{ dataranger.test_matches_control_totals(
        model=ref('fct_payments_cents'), totals=ref('source_totals'),
        date_column='paid_on', amount_column='amount', segment_column='channel',
        amount_tolerance=0.01) }}
)
select 'unit change not isolated to its day' as problem
where (select count(*) from failures) <> 3
   or (select count(*) from failures where day <> cast('2026-11-04' as date)) <> 0
