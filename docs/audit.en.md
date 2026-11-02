# Full SQL TIL audit — environments, snapshots and corrections

[한국어](audit.ko.md) · [Home](../README.md)

Audit date: 2026-11-02. All **115 final queries across 22 sessions** executed successfully with MySQL **8.4.11** and **ONLY_FULL_GROUP_BY enabled**, using the adaptations below. [Per-query results and hashes](audit-results.json) identify the exact published final SQL. Historical outputs and execution times were not overwritten with new runs.

## Execution scope

- Days1–3: historical `Match` / `date` names mapped to current `matches` / `match_date`. The original engine/version/sql_mode are not independently established. SQLite-style errors and permissive aggregate outputs must not be labeled as successes under default MySQL settings.
- Days4–5 and 9–11: the pre-deletion Olist backup was restored to an isolated temporary schema. Study databases were not overwritten. Orders and customers each contain 99,441 rows; every order matches a customer_id and this join does not multiply orders. There are 96,096 distinct customer_unique_id values.
- Days6,12–13,18–19: current finance table, one row per transaction; 1,048,567 transactions, 884,265 customers, dates 2016-08-01 through 2016-10-21, no missing date/amount values. Currency is not established by the retained source/schema.
- Days14–15 and 20: isolated views exposing only Baku session 11377. Every source table is scoped; filtering only the final output of a season-wide aggregate is not equivalent.
- Day21: isolated views exposing the 18 main races through Austin, excluding newly added Mexico session 11404. Old unfiltered SQL is preserved as a historical snapshot query.
- Day22: Exercise 1 Austin 11396; Exercise 2 all 19 main races through Mexico; Exercises 3–5 current retail_study. Retail also supports Days16–17.

Temporary audit schemas were removed after verification. Raw data, backups, complete private outputs and original finance identifiers are not published.

## Findings and corrections

| Finding | Verified outcome |
| --- | --- |
| Day1 Exercise 9, 2012/2013 mean home goals | Corrected 1.552 to 1.55: 5,053 / 3,260 |
| Day2 boolean-group / ungrouped-aggregate attempts | Current MySQL reports ERROR 1055 / 1140; historical outputs have separate environment status |
| Day3 malformed COUNT/FROM/comparison notation | Formatting repaired; learning mistakes remain distinguished from final answers |
| Day3 HAVING COUNT(*) | Valid truth test, but not the required >= 3250 filter |
| Day6 INR label | Currency changed to unspecified, rather than treating a plausible source assumption as proven |
| Day7 Exercise 3 | Original query executes with ONLY_FULL_GROUP_BY: 188 rows |
| Day7 Exercise 5 / Day8 Exercise 1 | Both return 109 teams; intersection 84, 25 unique to each condition |
| Day8 Exercise 2 | Selected aliases in the ORDER BY expression are valid MySQL: 62 rows |
| Day8 three-branch CASE | 3,326 matches, no missing scores or unclassified rows; missing scores in other data need a policy |
| Day12 frequency distribution | Reconciles to 884,265 customers and 1,048,567 transactions |
| Day15 Exercise 5 | Mean of raw driver means: 115.90 |
| Day16 Exercises 4–5 | 1668 qualifying customers; mean customer total 4678.46 |
| Day17 Exercises 4–5 | 1692 qualifying customers; mean customer total 3915.73 |
| Day18 Exercises 4–5 | 17685 qualifying customers; mean customer total 4878.81 |
| Day21 Exercises 1–5 | 19 / 11 / 8 / 23 / 24 result rows |
| Day22 Exercises 1–5 | 11 / 8 / 1668 / 4338 / 4346 result rows |

## Interpretation and limits

Distinct team IDs can share a name: use the entity ID plus display name when they must remain separate. The 2015/2016 away-match subset has no such name collisions. A UNIQUE key combined with the current INNER JOIN can support MySQL functional-dependence detection even when the original key declaration permits NULL; a non-PK nullable declaration alone does not establish that the recorded query must fail.

CASE ELSE omission is not an error by itself. COUNT ignores NULL but counts zero; adding ELSE 0 to a conditional COUNT changes its meaning. Missing scores must not silently become draws. Grouping and partitioning have different roles, and round only the display when rank/filter/order require the original amount.

Historical excerpts can omit time-of-day, abbreviate team names or leave unshared cells blank. Blank source cells are not claims of SQL NULL. LIMIT without a complete tie-breaker can select different boundary rows; unordered LIMIT has no guaranteed row sequence. These presentation/selection differences were distinguished from numeric errors. No claim is made that every historical output byte or original error cause was reproduced.

The repository does not distribute the datasets/backups or the local temporary schemas. Align names, keys and snapshots before rerunning. Successful execution and the documented checks do not certify every interpretation, untouched historical environment or production readiness. Historical runtime measurements remain historical.

## Reference behavior

- [MySQL GROUP BY handling](https://dev.mysql.com/doc/refman/8.4/en/group-by-handling.html)
- [MySQL functional dependence](https://dev.mysql.com/doc/refman/8.4/en/group-by-functional-dependence.html)
- [MySQL aliases](https://dev.mysql.com/doc/refman/8.4/en/problems-with-alias.html)
- [MySQL CASE behavior](https://dev.mysql.com/doc/refman/8.4/en/flow-control-functions.html)
- [SQLite bare aggregate columns](https://www.sqlite.org/lang_select.html#bareagg)
