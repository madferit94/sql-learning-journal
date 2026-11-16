# SQL Learning Journal

[한국어](README.ko.md) | English

A bilingual SQL TIL (Today I Learned) journal documenting my practice toward data analysis, using real datasets from varied domains including sports, e-commerce, finance and music.

The focus is learning to turn a question into a query, understand the unit of each row, diagnose mistakes and check results. The aim is to apply SQL across changing datasets and questions.

## Study index

| Day | Topic | Korean | English | SQL |
| --- | --- | --- | --- | --- |
| 01 | Selection, filtering and aggregation | [한글](til/ko/day01.md) | [English](til/en/day01.md) | [Queries](sql/day01.sql) |
| 02 | Aggregation and row filters | [한글](til/ko/day02.md) | [English](til/en/day02.md) | [Queries](sql/day02.sql) |
| 03 | WHERE and HAVING | [한글](til/ko/day03.md) | [English](til/en/day03.md) | [Queries](sql/day03.sql) |
| 04 | Olist order aggregation | [한글](til/ko/day04.md) | [English](til/en/day04.md) | [Queries](sql/day04.sql) |
| 05 | Customer identifiers and joins | [한글](til/ko/day05.md) | [English](til/en/day05.md) | [Queries](sql/day05.sql) |
| 06 | Transaction aggregation and CASE | [한글](til/ko/day06.md) | [English](til/en/day06.md) | [Queries](sql/day06.sql) |
| 07 | Football joins and team aliases | [한글](til/ko/day07.md) | [English](til/en/day07.md) | [Queries](sql/day07.sql) |
| 08 | Football classification and outcomes | [한글](til/ko/day08.md) | [English](til/en/day08.md) | [Queries](sql/day08.sql) |
| 09 | Olist joins and two-stage aggregation | [한글](til/ko/day09.md) | [English](til/en/day09.md) | [Queries](sql/day09.sql) |
| 10 | Monthly metrics and repeat customers | [한글](til/ko/day10.md) | [English](til/en/day10.md) | [Queries](sql/day10.sql) |
| 11 | Conditional aggregation and subqueries | [한글](til/ko/day11.md) | [English](til/en/day11.md) | [Queries](sql/day11.sql) |
| 12 | Customer aggregation and transaction distribution | [한글](til/ko/day12.md) | [English](til/en/day12.md) | [Queries](sql/day12.sql) |
| 13 | Conditional counts, amounts and customer totals | [한글](til/ko/day13.md) | [English](til/en/day13.md) | [Queries](sql/day13.sql) |
| 14 | Baku F1 joins and conditional aggregation | [한글](til/ko/day14.md) | [English](til/en/day14.md) | [Queries](sql/day14.sql) |
| 15 | Baku F1 practice and aggregate subqueries | [한글](til/ko/day15.md) | [English](til/en/day15.md) | [Queries](sql/day15.sql) |
| 16 | Online Retail quantities, customer joins and totals | [한글](til/ko/day16.md) | [English](til/en/day16.md) | [Queries](sql/day16.sql) |
| 17 | Online Retail monthly aggregation, date filters and subqueries | [한글](til/ko/day17.md) | [English](til/en/day17.md) | [Queries](sql/day17.sql) |
| 18 | Finance monthly metrics, distinct transaction days and subqueries | [한글](til/ko/day18.md) | [English](til/en/day18.md) | [Queries](sql/day18.sql) |
| 19 | Finance aggregation review and CTE foundations | [한글](til/ko/day19.md) | [English](til/en/day19.md) | [Queries](sql/day19.sql) |
| 20 | F1 joins, CTEs and introductory window functions | [한글](til/ko/day20.md) | [English](til/en/day20.md) | [Queries](sql/day20.sql) |
| 21 | F1 Austin results, multi-race points totals and rankings | [한글](til/ko/day21.md) | [English](til/en/day21.md) | [Queries](sql/day21.sql) |
| 22 | F1 review, customer totals and overall/country rankings | [한글](til/ko/day22.md) | [English](til/en/day22.md) | [Queries](sql/day22.sql) |
| 23 | Music track/video rankings, CAST and conditional aggregation | [한글](til/ko/day23.md) | [English](til/en/day23.md) | [Queries](sql/day23.sql) |
| 24 | F1 aggregation, ranks and a scoped team correction | [한글](til/ko/day24.md) | [English](til/en/day24.md) | [Queries](sql/day24.sql) |
| 25 | Groupwise top N, chained CTEs and representative transactions | [한글](til/ko/day25.md) | [English](til/en/day25.md) | [Queries](sql/day25.sql) |

## What the record covers

- SELECT, WHERE, ORDER BY, GROUP BY, HAVING, JOIN, CASE WHEN, DISTINCT and date functions.
- Aggregate subqueries and CTEs for customer/driver-level intermediate results.
- RANK and PARTITION BY for overall and within-team rankings.
- Row grain, join keys, NULL treatment, denominators, team changes and metric interpretation.

The journal contains 25 sessions and 131 final recorded queries (including the Day24 correction example).

Solutions are written directly; AI is used for grading and feedback on mistakes.

## Data and execution

Examples use European Soccer Database, Olist, a transaction practice table, UCI Online Retail and F1 snapshots. Read the [data and schema notes](docs/data.en.md). Raw datasets, dumps, credentials, private Notion exports and machine-specific paths are excluded.

Result tables retain historical executions. A separate 2026-11-02 audit reran the existing 115 final queries with explicit schema/snapshot adaptations, followed by a separate five-query Day23 check; see [audit findings](docs/audit.en.md). Day19 Exercise 1 includes the subsequently supplied three-row result and its recorded database cross-check. F1 Days14–15 and 20 describe a Baku-only snapshot; Day21 uses 18 main races through Austin; Day22 uses the later 19-race snapshot through Mexico and Online Retail. Reusing an old unfiltered query after expanding the database can combine races, so specify session scope before running it.

Main-race points exclude Sprints and RANK ties do not implement official championship tie-breaking. A timed-lap cutoff or an all-lap mean is not an official classification or a controlled ability comparison.

## How to study

1. Read the question, table structure and output grain before opening the solution.
2. Write a query, then compare keys, filters, groups and denominators.
3. Check the result and explain what one row and each metric mean.
4. Revisit a changed condition without the previous answer.

The Korean edition follows the detailed Notion record; English is an edited translation covering the same exercises, final SQL, output values and interpretation limits. [Editorial and validation notes](docs/editorial.en.md) describe publication checks.

Source: [Notion SQL TIL](https://www.notion.so/7b736fd8bbd949ca93f84cdc66987ace) (access may be required). Publication snapshot: 2026-11-16. This is a manual synchronization, not an automatic background sync.

Days24–25 use 20 main races through Brazil and finance transactions. Eleven added queries received separate read-only execution/count checks; unshared historical result counts/runtimes are not inferred. Finance output identifiers are pseudonymized.
