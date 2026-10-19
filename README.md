# SQL Learning Journal

[한국어](README.ko.md) | English

A bilingual SQL TIL (Today I Learned) journal documenting my practice toward data analysis: **17 study sessions and 90 exercises**, using football, e-commerce and transaction examples.

The focus is learning to turn a question into a query, understand the unit of each row, diagnose mistakes and check results. This is a learning record, not a claim of independent mastery or a production-ready analytics project.

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
| 15 | Baku F1 independent practice and aggregate subqueries | [한글](til/ko/day15.md) | [English](til/en/day15.md) | [Queries](sql/day15.sql) |
| 16 | Online Retail quantities, customer joins and totals | [한글](til/ko/day16.md) | [English](til/en/day16.md) | [Queries](sql/day16.sql) |
| 17 | Online Retail monthly aggregation, date filters and subqueries | [한글](til/ko/day17.md) | [English](til/en/day17.md) | [Queries](sql/day17.sql) |

## What the record covers

- Practiced: SELECT, WHERE, ORDER BY, LIMIT, GROUP BY, HAVING, JOIN, CASE WHEN, DISTINCT, date functions and aggregate subqueries.
- Still consolidating: conditional aggregation, two-stage aggregation, customer-level denominators and writing queries independently.
- Next learning goals: CTEs and window functions. These are **not** presented as completed topics.

AI has supported explanations, debugging and the preparation of this bilingual publication. Earlier attempts and unresolved issues remain visible; the record does not label AI-assisted work as independently completed.

## Data and execution

The Notion notes identify MySQL 8.4. They use European Soccer Database, Olist and a transaction practice table. Raw datasets, database credentials and local imports are not included. Source schemas differ between days, so these files are not a one-command executable project. Read the [data and schema notes](docs/data.en.md) before adapting a query.

Results are historical outputs transcribed from Notion, **not newly executed or independently verified for this publication**. Day11 Exercise 3 retains its original ERROR 1064 history and now includes the learner's successful October 10 follow-up. See the [editorial and validation notes](docs/editorial.en.md).

## How to study with this repository

1. Read a question and predict the output grain before looking at the solution.
2. Write a query independently; compare the attempt and explanation only after trying.
3. Check keys, row counts, filters, grouping and denominators.
4. Record the mistake, its cause and a new variation to solve without the answer.

The Korean edition preserves the detailed journal with formatting cleanup. The English edition covers every exercise with translated questions, learning points, selected attempts, final recorded queries and available output excerpts; repeated commentary is condensed.

Source: [Notion SQL TIL](https://www.notion.so/7b736fd8bbd949ca93f84cdc66987ace) (access may be required). Publication snapshot: 2026-10-19. This is a manual snapshot, not an automatic Notion sync.

Recent progress: Day16 Exercises 4 and 5 were accepted on the first submission: 1,668 qualifying customers and a mean customer total of GBP 4,678.46. This demonstrates transfer of the practiced aggregate-subquery pattern, not mastery of every subquery form. Day16 spans October 15–16.
