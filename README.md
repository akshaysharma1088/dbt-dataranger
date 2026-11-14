# dataranger (dbt package)

**dbt tests pass. The numbers are still wrong.** `not_null` and `unique` cannot see a join that
counts some orders twice, a filter that drops a day, or a column that quietly switched from dollars
to cents. This package adds the check that can: reconcile a model against the raw table it was
built from, day by day.

It is the dbt side of [DataRanger](https://github.com/akshaysharma1088/dataranger), the open-source
agent that fixes only the data problems it can prove against the source. The package works on its
own. No Python and no agent are needed to use the tests.

## Install

```yaml
# packages.yml
packages:
  - package: akshaysharma1088/dataranger
    version: [">=0.1.0", "<0.2.0"]
```

Then run `dbt deps`. Works with dbt 1.10 and later. It uses only standard SQL and dbt's
cross-database macros, and is tested on DuckDB in CI.

## 1. Reconcile a model with its raw table

```yaml
models:
  - name: fct_payments
    data_tests:
      - dataranger.reconciles_with_source:
          arguments:
            source_relation: source('erp', 'payments')
            source_date_column: txn_date
            source_amount_column: amt
            source_where: "status <> 'test'"   # the rows that should reach the model
            date_column: paid_on
            amount_column: amount
            segment_column: channel            # optional: check each day and channel
            amount_tolerance: 0.0001           # optional: allow 0.01% rounding drift
```

The test fails with one row per day (and segment) that does not reconcile, showing both sides:

| day | segment | rows_in_model | rows_expected | amount_in_model | amount_expected |
|---|---|---|---|---|---|
| 2026-11-01 | * | 18 | 16 | 2095.03 | 1814.23 |
| 2026-11-04 | * | 19 | 16 | 1776.12 | 1594.39 |

That is a join fanning out on two days. Every other test on the model was green.

| Argument | Meaning | Default |
|---|---|---|
| `source_relation` | The raw or staging table the model is built from | required |
| `date_column`, `amount_column` | The model's date and amount columns | required |
| `source_date_column`, `source_amount_column` | The same columns in the source, if named differently | the model's names |
| `segment_column`, `source_segment_column` | Break each day down by a column such as channel or region | whole days only |
| `source_where` | Filter for the source rows that should reach the model | all rows |
| `where` | Filter for the model's rows, for example the last 30 days | all rows |
| `amount_tolerance`, `count_tolerance` | Allowed relative difference, `0.01` is 1% | `0`, exact |

## 2. Keep control totals as a model

On a large source, scanning the raw table in every test is wasteful. Build the totals once:

```sql
-- models/payments_control_totals.sql
{{ dataranger.control_totals(
    source('erp', 'payments'), 'txn_date', 'amt',
    segment_column='channel', where="status <> 'test'", date_alias='paid_on') }}
```

It returns one row per day and segment, plus a `*` row for the whole day, with the row count `n`
and the summed `amount`. Then test against it:

```yaml
      - dataranger.matches_control_totals:
          arguments:
            totals: ref('payments_control_totals')
            date_column: paid_on
            amount_column: amount
            segment_column: channel
```

Leave `segment_column` out to compare whole days against the `*` rows; in that case name the
totals' segment column with `totals_segment_column`.

If your source system already sends its own control totals (many finance and payment feeds do),
point `totals` at that table instead. Those are stronger evidence, because they do not pass through
your pipeline at all.

## 3. Let DataRanger repair what the tests find

The control totals model is exactly what DataRanger reads. Name it on the fact model and patrol:

```yaml
models:
  - name: fct_payments
    meta:
      dataranger:
        manifest_model: payments_control_totals
        ref_model: dim_customers
        key: payment_id
        reference: customer_id
        ref_key: customer_id
        date: paid_on
        segment: channel
        amount: amount
```

```bash
pip install "dataranger[dbt]"
dataranger patrol --dbt-model fct_payments
```

DataRanger finds the broken days, tries each fix on a copy, applies only the fixes that reconcile
with the totals, and hands the rest to a person with the evidence.

## Development

```bash
pip install dbt-duckdb
cd integration_tests
dbt deps && dbt build
```

The integration project builds a clean model, a model with a join fan-out and a model with a unit
change, and checks that the clean one passes and the other two are caught.

## License

MIT
