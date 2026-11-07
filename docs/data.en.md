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

## Days18–21 update: finance, CTEs and multi-race F1

Days18–19 continue bank_transactions. Public IDs use FIN_CUSTOMER pseudonyms consistent with existing Days12–13 examples; additional labels extend that mapping within this journal. Currency remains unspecified. No private mapping or raw transaction data is published.

Day20 retains the Baku-only 11377 snapshot. The 40-timed-lap cutoff is instructional, not official or statistically validated. Day14/15 selection explanations distinguish total-timed-lap cutoffs, team-combined record cutoffs and counts under a time threshold. These are different eligibility rules.

Day21 uses 18 2026 main races through United States/Austin (11396), excluding two cancelled sessions, Sprints, qualifying and practice. The local expansion has sessions 18 rows, drivers 396, laps 20811, stints 1119 and race_results 396. Stored Baku rows were preserved. The preparation report records full source-to-DB row/cell matching and no orphan driver joins; exercise SQL was not rerun in that original publication; the later 2026-11-02 scoped replay is documented separately.

Official position, completed_laps and points were reconciled for 396 records against [F1 published results](https://www.formula1.com/en/results/2026/races). Other timing fields come from [OpenF1](https://openf1.org/docs/), an unofficial API. status is derived from DSQ/DNS/DNF flags; official_position_label and official_time_or_retired preserve published labels. A NULL position must not be silently replaced by a points rank.

Known source caveats: 118 NULL lap durations, six reversed/empty stint intervals, and session 11731's inconsistent API location/circuit metadata (Kuala Lumpur versus Bahrain in the country and official event record). Raw fields are preserved; grand_prix_name supplies the official event label. Do not treat that session's location/timezone fields as verified geography or use invalid stint intervals as real lap ranges.

After expansion, old unfiltered Baku SQL can combine races. Filter a session or group/partition by session_key when the metric is per race. Never compare raw average lap seconds across different circuits as an ability ranking. Main-race points exclude Sprints; RANK does not implement official championship tie-breaking.


## Day22: Mexico update and retail rankings

Mexico main race 11404 was added after Austin. The current snapshot has sessions 19, drivers 418, laps 22171, stints 1199 and race_results 418. New rows: 1 session, 22 driver appearances, 1360 laps, 80 stints and 22 results. All prior 18-race rows were preserved; the 66 official position/lap/point fields matched without differences. New lap_duration NULLs: 5, making 123 overall; the earlier six invalid stint intervals remain flagged, with no new reversed intervals. Sources: [OpenF1](https://openf1.org/docs/) and [F1 Mexico results](https://www.formula1.com/en/results/2026/races/1298/mexico/race-result).

Historical lessons keep their old snapshot scope. Current full-query replay is documented in the [audit](audit.en.md), including isolated Olist restoration, schema-name mapping and F1 snapshot views. This supersedes older statements that no query was rerun for any publication update. Original outputs and timings still describe their historical executions.


## Day23: music_study

The Beatles snapshot is recorded as collected from kworb on 2026-11-05: 500 individual Spotify tracks and 89 official YouTube videos. Track/video IDs are public platform identifiers. Platforms were analyzed separately; song/version aggregation, cross-platform matching and Hot100 were not performed. Source dates and prior-day figures are not current live metrics.

beatles_spotify_tracks: row_id INT PK, track_id VARCHAR(22), title VARCHAR(255), streams BIGINT, all NOT NULL. beatles_youtube_videos: video_id VARCHAR(11) PK, title VARCHAR(255), views BIGINT, all NOT NULL; views_yesterday BIGINT nullable. Actual NULL counts for the two view metrics are zero. utf8mb4_0900_as_cs distinguishes case and accents, but does not guarantee identical comparison semantics to Python for all Unicode strings.

Raw CSVs, loaders, authentication files and private project paths are not published. The journal introduction now describes applying SQL principles across varied domains. Music practice connects to Numberlog content planning, without claiming platform effects or causality.
