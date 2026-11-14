-- The fan-out must be reported. This test fails if the check finds nothing.
with failures as (
    {{ dataranger.test_reconciles_with_source(
        model=ref('fct_payments_fanout'), source_relation=ref('raw_payments'),
        date_column='paid_on', amount_column='amount',
        source_date_column='txn_date', source_amount_column='amt', source_where="status <> 'test'",
        amount_tolerance=0.000001) }}
)
select 'fan-out was not caught' as problem
where (select count(*) from failures) = 0
