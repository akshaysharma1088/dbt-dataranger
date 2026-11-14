-- The same model after someone "standardized" amounts to cents on the last day only.
select txn_id as payment_id, customer_id, cast(txn_date as date) as paid_on, channel,
       case when txn_date = '2026-11-04' then amt * 100 else amt end as amount
from {{ ref('raw_payments') }}
where status <> 'test'
