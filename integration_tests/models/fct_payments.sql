select txn_id as payment_id, customer_id, cast(txn_date as date) as paid_on, channel, amt as amount
from {{ ref('raw_payments') }}
where status <> 'test'
