-- Control totals built from the raw table: what should have arrived in fct_payments.
{{ dataranger.control_totals(ref('raw_payments'), 'txn_date', 'amt', segment_column='channel',
                             where="status <> 'test'", date_alias='paid_on') }}
