# Day 25 — Groupwise top N, chained CTEs and ROW_NUMBER

[한국어](../ko/day25.md) · [Index](../../README.md)

Exercises 1–3 use f1_study, the 20-main-race snapshot through Brazil; 4–5 use finance.bank_transactions. Exclude F1 NULL team names without changing the source DB. This session transfers the same window-selection structure across domains. Historical outputs and later read-only checks remain separate.

```bash
mysql -u root -p
```

```sql
USE f1_study;
-- Exercises 4–5:
USE finance;
```

## Exercise 1 — Within-team cumulative points ranks

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Use CTE and RANK over all 20 races. Exclude NULL team names without correcting them; group by team_name, driver_number, full_name and split transfers. Include all result registrations. Equal points tie and skip ranks. Return team_name, team_rank, driver_number, full_name, race_count, total_points; one team-driver pair per row. Sort team_name, team_rank, driver_number ascending.

**Fictional example.** Fictional points 100/80/80/50 yield ranks 1/2/2/4.

### Final query recorded in the journal

```sql
WITH f1_race AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.full_name, d.driver_number
)
SELECT team_name,
       RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
       driver_number, full_name, race_count, total_points
FROM f1_race
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### Recorded output (source excerpt)

| team_name | team_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| Haas F1 Team | 3 | 51 | Rafael CAMARA | 1 | 0.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Racing Bulls | 3 | 22 | Yuki TSUNODA | 3 | 1.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Red Bull Racing | 3 | 30 | Liam LAWSON | 3 | 14.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

The terminal footer is truncated; no historical row count or runtime is inferred.

### Correction and interpretation

The first attempt omitted PARTITION BY and would rank all teams together. Add team partitioning and group by team/number/name. Display sorting alone cannot create within-team ranks. No unshared database error text is invented.

## Exercise 2 — Drivers ranked within the top two of each team

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Same 20-race scope, join keys, NULL exclusion and aggregation as Exercise 1. Use RANK and retain within-team ranks <= 2, including all boundary ties; not exactly two people. Return team_name, team_rank, driver_number, full_name, race_count, total_points. Sort team_name, team_rank, driver_number ascending.

**Fictional example.** Fictional team points 100/80/80 retain three drivers for rank <= 2.

### Final query recorded in the journal

```sql
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number, d.full_name
),
2026_top2_rank AS (
    SELECT team_name,
           RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
           driver_number, full_name, race_count, total_points
    FROM 2026_f1
)
SELECT team_name, team_rank, driver_number, full_name, race_count, total_points
FROM 2026_top2_rank
WHERE team_rank <= 2
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### Recorded output (source excerpt)

| team_name | team_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

User terminal: 22 rows in set (0.11 sec).

### Correction and interpretation

The first attempt tried HAVING team_rank <= 2 at the window-calculation level. Add another CTE so the outer WHERE filters completed ranks: aggregate, rank, then select. The current 22 rows do not guarantee two drivers under future boundary ties.

## Exercise 3 — Select at most two drivers per team

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Same scope, keys, NULL exclusion and aggregation as Exercise 1. Use ROW_NUMBER within each team ordered by total_points DESC, driver_number ASC. Keep numbers 1 and 2 only; a team with one eligible driver yields one row. Return team_name, selection_no, driver_number, full_name, race_count, total_points; selection_no is not an official rank. Sort team_name ASC, selection_no ASC.

**Fictional example.** Fictional drivers 8:100, 25:80, 31:80 select 8 and 25 only.

### Final query recorded in the journal

```sql
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number, d.full_name
),
f1_selection AS (
    SELECT team_name,
           ROW_NUMBER() OVER (
               PARTITION BY team_name
               ORDER BY total_points DESC, driver_number ASC
           ) AS selection_no,
           driver_number, full_name, race_count, total_points
    FROM 2026_f1
)
SELECT team_name, selection_no, driver_number, full_name, race_count, total_points
FROM f1_selection
WHERE selection_no <= 2
ORDER BY team_name ASC, selection_no ASC;
```

### Recorded output (source excerpt)

| team_name | selection_no | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 2 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

User terminal: 22 rows in set (0.07 sec).

### Correction and interpretation

Selection logic was correct; final display sorting was corrected from points order to team_name/selection_no. Window ordering selects the rows; final ordering displays them. Cadillac’s zero-point drivers tie at RANK 1 but get row numbers 1 and 2 by driver number.

## Exercise 4 — One representative transaction on each customer’s latest date

### Table and row grain

bank_transactions: one row per transaction. transaction_id VARCHAR(20) PRIMARY KEY, customer_id VARCHAR(20), transaction_date DATE, transaction_amount DECIMAL(15,2); all four non-NULL. Currency is not established. Do not use transaction_time; the task does not identify the last intraday transaction.

### Question and conditions

Use only bank_transactions and ROW_NUMBER. Select one transaction per customer ordered by transaction_date DESC, transaction_amount DESC, transaction_id ASC (string order). Include single-transaction customers. Return the original customer_id, transaction_id, transaction_date, transaction_amount without summing. Ignore time of day. One representative per customer; final customer_id ASC.

**Fictional example.** Fictional C01 has an older 9000 transaction and two latest-date amounts 500/800: select 800.

### Final query recorded in the journal

```sql
WITH recent_transaction AS (
    SELECT customer_id, transaction_id, transaction_date, transaction_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY transaction_date DESC,
                        transaction_amount DESC,
                        transaction_id ASC
           ) AS rn
    FROM bank_transactions
)
SELECT customer_id, transaction_id, transaction_date, transaction_amount
FROM recent_transaction
WHERE rn <= 1
ORDER BY customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | transaction_id | transaction_date | transaction_amount |
| --- | --- | --- | --- |
| CUSTOMER_001 | TXN_007 | 2016-09-26 | 4750.00 |
| CUSTOMER_002 | TXN_009 | 2016-08-14 | 1499.00 |
| CUSTOMER_003 | TXN_006 | 2016-08-07 | 250.00 |
| CUSTOMER_004 | TXN_022 | 2016-09-15 | 30.00 |
| CUSTOMER_005 | TXN_011 | 2016-08-18 | 5000.00 |
| CUSTOMER_006 | TXN_018 | 2016-08-29 | 557.00 |
| CUSTOMER_007 | TXN_003 | 2016-08-04 | 1460.00 |
| CUSTOMER_008 | TXN_014 | 2016-08-27 | 700.00 |
| CUSTOMER_009 | TXN_017 | 2016-08-26 | 208.00 |
| CUSTOMER_010 | TXN_005 | 2016-08-09 | 19680.00 |
| CUSTOMER_011 | TXN_021 | 2016-09-07 | 100.00 |

Only a supplied output excerpt is shown. Full row count and historical runtime were not supplied.

### Correction and interpretation

The first attempt used date DESC then transaction_id DESC, omitting amount. The correction was initially applied to final output order, then moved inside ROW_NUMBER while restoring customer_id display order. Matching early output rows do not establish correct tie handling.

## Exercise 5 — Customers whose representative transaction is at least 5000

### Table and row grain

bank_transactions: one row per transaction. transaction_id VARCHAR(20) PRIMARY KEY, customer_id VARCHAR(20), transaction_date DATE, transaction_amount DECIMAL(15,2); all four non-NULL. Currency is not established. Do not use transaction_time; the task does not identify the last intraday transaction.

### Question and conditions

Choose each customer’s representative from all transactions first: date DESC, amount DESC, transaction_id ASC. Use bank_transactions and ROW_NUMBER, not time of day. Keep only representatives with amount >= 5000. Older high-value rows cannot qualify a customer whose representative is below the threshold. Return customer_id, transaction_id, transaction_date, transaction_amount. Final amount DESC, customer_id ASC.

**Fictional example.** Fictional C01 with older 9000 and latest 500 is excluded; C02 representative 7000 and C03 representative 5000 qualify.

### Final query recorded in the journal

```sql
WITH recent_transaction AS (
    SELECT customer_id, transaction_id, transaction_date, transaction_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY transaction_date DESC,
                        transaction_amount DESC,
                        transaction_id ASC
           ) AS rn
    FROM bank_transactions
)
SELECT customer_id, transaction_id, transaction_date, transaction_amount
FROM recent_transaction
WHERE transaction_amount >= 5000 AND rn <= 1
ORDER BY transaction_amount DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | transaction_id | transaction_date | transaction_amount |
| --- | --- | --- | --- |
| CUSTOMER_021 | TXN_010 | 2016-08-18 | 1560034.99 |
| CUSTOMER_020 | TXN_016 | 2016-08-22 | 1380002.88 |
| CUSTOMER_015 | TXN_013 | 2016-08-23 | 991132.22 |
| CUSTOMER_013 | TXN_015 | 2016-08-03 | 720001.16 |
| CUSTOMER_019 | TXN_020 | 2016-09-09 | 600008.32 |
| CUSTOMER_017 | TXN_004 | 2016-08-04 | 600003.45 |
| CUSTOMER_016 | TXN_008 | 2016-08-14 | 569500.27 |
| CUSTOMER_012 | TXN_002 | 2016-08-05 | 561001.00 |
| CUSTOMER_018 | TXN_012 | 2016-08-18 | 557000.73 |
| CUSTOMER_014 | TXN_001 | 2016-09-13 | 550004.34 |
| CUSTOMER_022 | TXN_019 | 2016-09-06 | 543699.36 |

Only a supplied output excerpt is shown. Full row count and historical runtime were not supplied.

### Correction and interpretation

All transactions are numbered before the outer amount and rn conditions. AND predicate writing order does not change the result. rn <= 1 equals rn = 1 because numbering starts at one; rn >= 1 admits every numbered transaction and loses representative selection.

## Concepts and review

RANK retains ties; ROW_NUMBER assigns unique numbers using explicit tie-breakers. UNION ALL in the teaching example only constructs fictional rows and is not required by the window function. No execution of that sample was supplied. Window ORDER BY controls selection; final ORDER BY controls display. Number all transactions before applying the representative amount threshold. rn >= 1 admits every row. Independent delayed re-solving is not yet verified.

Finance output customer/transaction IDs are consistently pseudonymized in this public edition. Row order retains the original ID-based query order; pseudonyms are not re-sorted. Dates, amounts and SQL are unchanged. Notion retains submitted IDs.
