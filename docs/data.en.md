# Data and schema notes

[한국어](data.ko.md) · [Home](../README.md)

| Dataset | Days | Source and limitations |
| --- | --- | --- |
| European Soccer Database | 1–3, 7–8 | The journal credits Hugo Mathien and Kaggle. Days1–3 use `Match` and `date`; Days7–8 use local `matches` and `match_date`, plus `league` and `team`. The local import/rename procedure is not available here. |
| Brazilian E-Commerce / Olist | 4–5, 9–11 | The journal identifies the Olist dataset on Kaggle. Queries use local `orders` and `customers` tables. `customer_id` is the order-linked join key; `customer_unique_id` identifies a customer across orders. |
| Transaction practice table | 6 | `finance.bank_transactions`. The original provider URL and redistribution terms could not be established from the notes. No claim is made that these are employer or bank-internal records. |

No raw datasets or database dumps are redistributed. The transaction journal records 1,048,567 rows and a date range of 2016-08-01 to 2016-10-21; these are historical notes, not freshly verified counts. Its customer IDs have been replaced consistently with `CUSTOMER_001`-style pseudonyms in the public record.

Before running a query, obtain the relevant data legitimately, inspect the actual schema and adapt table/column names. Check row counts, key uniqueness, missing values, unmatched joins and coverage. Source outputs alone do not supply the complete import steps or constraints needed for exact reproduction.

## Added datasets and local schema (2026-10-16)

- Days12–13 continue `finance.bank_transactions` (one row per transaction). Customer IDs in these additions use consistent `FIN_CUSTOMER_001` pseudonyms; the mapping scope is Days12–13, separate from the existing Day06 publication. No raw bank records are redistributed.
- Days14–15 use the [Baku F1 repository snapshot](https://github.com/madferit94/all-sports-analytics/tree/c1e22c8f1d0f14192f92159d59b7b8f12a307ef5/f1/baku-2026). This is a stored project snapshot, not a live OpenF1 retrieval or an independent validation of race facts. `laps` has 983 rows, 976 timed laps and 7 NULL durations; `drivers` has 22 rows. Join by session_key and driver_number. Never join tyre stints by driver alone. An all-lap mean or a 109/110-second threshold is not a controlled comparison of driver ability.
- Day16 uses [UCI Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail), Daqing Chen (2015), DOI 10.24432/C5BW33, CC BY 4.0. Original line items: 541,909; distinct invoice numbers: 25,900. `sales_items` exposes 530,104 rows with positive quantity/price and no C-prefixed invoice. Original duplicate rows remain. Price is GBP. Unknown-customer rows remain in country analysis but are excluded from customer analysis.
- `invoice_headers` is a derived teaching table with 25,943 unique combinations of invoice number, timestamp, customer and country. Forty-three invoice numbers have multiple combinations. Its row count is not a distinct-order count. Join items using invoice_header_id; invoice_no alone may multiply rows. The original fields are retained in invoice_items.

Schema-only files: [F1](../sql/schema-f1.sql), [Retail](../sql/schema-retail.sql). They do not include data or a one-command loader. The original workbook was compared against all imported fields (with declared text/type conversion); source-to-DB matching does not certify the business truth of every source record. Numeric descriptions are preserved as strings. Raw duplicates, cancellations and missing IDs require an explicit analysis policy before calling these exercise totals audited revenue.
