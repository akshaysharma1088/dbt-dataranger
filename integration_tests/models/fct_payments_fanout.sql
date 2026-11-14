-- The same model with a join to a table that has two rows for one customer.
select p.txn_id as payment_id, p.customer_id, cast(p.txn_date as date) as paid_on, p.channel, p.amt as amount, a.city
from {{ ref('raw_payments') }} p
join {{ ref('customer_addresses') }} a on a.customer_id = p.customer_id
where p.status <> 'test'
