# Data and schema notes

[한국어](data.ko.md) · [Home](../README.md)

| Dataset | Days | Source and limitations |
| --- | --- | --- |
| European Soccer Database | 1–3, 7–8 | The journal credits Hugo Mathien and Kaggle. Days1–3 use `Match` and `date`; Days7–8 use local `matches` and `match_date`, plus `league` and `team`. The local import/rename procedure is not available here. |
| Brazilian E-Commerce / Olist | 4–5, 9–11 | The journal identifies the Olist dataset on Kaggle. Queries use local `orders` and `customers` tables. `customer_id` is the order-linked join key; `customer_unique_id` identifies a customer across orders. |
| Transaction practice table | 6 | `finance.bank_transactions`. The original provider URL and redistribution terms could not be established from the notes. No claim is made that these are employer or bank-internal records. |

No raw datasets or database dumps are redistributed. The transaction journal records 1,048,567 rows and a date range of 2016-08-01 to 2016-10-21; these are historical notes, not freshly verified counts. Its customer IDs have been replaced consistently with `CUSTOMER_001`-style pseudonyms in the public record.

Before running a query, obtain the relevant data legitimately, inspect the actual schema and adapt table/column names. Check row counts, key uniqueness, missing values, unmatched joins and coverage. Source outputs alone do not supply the complete import steps or constraints needed for exact reproduction.
