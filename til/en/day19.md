# Day 19 — Finance aggregation review and CTE foundations

[한국어](../ko/day19.md) · [Index](../../README.md)

The same finance table has one row per transaction, non-NULL customer IDs/dates/amounts, DATE transaction_date and DECIMAL(15,2) transaction_amount. Currency is unspecified. This session contains three review exercises and two CTE foundation exercises, not a completed window-function session. The originally proposed CTE customer-count task remains a later practice item.

## Tables and column types

bank_transactions: customer_id VARCHAR(20), transaction_date DATE, transaction_amount DECIMAL(15,2). One row is one transaction; the relevant fields are non-NULL.

## Exercise 1 — Monthly transaction statistics

**Question and conditions.** Return YYYY-MM transaction_month, transaction_count, total_transaction_amount and avg_transaction_amount across all periods. Include every row, round the mean to two decimals and show the total at two-decimal precision. Return observed months only, sorted ascending.

**Row grain, example and interpretation.** One row is one month. The later execution supplied three rows in 2.38 seconds; the Notion addendum also records a read-only database recheck matching every displayed aggregate.

### Final query recorded in the journal

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;
```

### Recorded output (source excerpt)

| transaction\_month | transaction\_count | total\_transaction\_amount | avg\_transaction\_amount |
| --- | --- | --- | --- |
| 2016-08 | 653933 | 1030599493.84 | 1576.00 |
| 2016-09 | 390975 | 612531219.10 | 1566.68 |
| 2016-10 | 3659 | 7665018.63 | 2094.84 |


Recorded execution: 3 rows in set (2.38 sec).

## Exercise 2 — Monthly high-value counts, totals and percentage

**Question and conditions.** For each observed month return transaction_month, transaction_count, high_amount_count, high_amount_total and high_amount_rate. High value is amount at least 5000. Sum only qualifying amounts but use all monthly rows as the percentage denominator. Round the percentage to two decimals. Keep zero-high-value months with zeros and sort month ascending.

**Row grain, example and interpretation.** COUNT(*) counts transactions, not distinct transaction dates. The conditional SUM returns the amount for matching rows and zero otherwise. COUNT(transaction_date) is the original denominator; with no date NULLs it equals COUNT(*). The displayed results retain only requested columns from the recorded execution.

### Final query recorded in the journal

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    SUM(
        CASE
            WHEN transaction_amount >= 5000 THEN transaction_amount
            ELSE 0
        END
    ) AS high_amount_total,
    ROUND(
        COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(transaction_date) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;
```

### Recorded output (source excerpt)

| transaction\_month | transaction\_count | high\_amount\_count | high\_amount\_total | high\_amount\_rate |
| --- | --- | --- | --- | --- |
| 2016-08 | 653933 | 35767 | 556043304.17 | 5.47 |
| 2016-09 | 390975 | 21446 | 329052383.08 | 5.49 |
| 2016-10 | 3659 | 246 | 5057837.26 | 6.72 |


## Exercise 3 — Customers meeting both active-day and cumulative-value conditions

**Question and conditions.** Return customer_id, transaction_count, active_day_count and total_transaction_amount for customers with at least three distinct dates and cumulative amount at least 10000. Include the exact boundaries and all their transactions. Dates need not be consecutive. Sort days descending, amount descending, then ID ascending.

**Row grain, example and interpretation.** SUM(CASE WHEN amount >= 10000 THEN amount ELSE 0 END) is a different metric: it selects large individual transactions. Three separate 4000 transactions total 12000 and satisfy the cumulative-value condition. The actual table is a leading-row excerpt.

### Final query recorded in the journal

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT transaction_date) AS active_day_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_amount >= 10000
   AND active_day_count >= 3
ORDER BY
    active_day_count DESC,
    total_transaction_amount DESC,
    customer_id ASC;
```

### Recorded output (source excerpt)

| customer\_id | transaction\_count | active\_day\_count | total\_transaction\_amount |
| --- | --- | --- | --- |
| FIN_CUSTOMER_027 | 6 | 6 | 14758.39 |
| FIN_CUSTOMER_028 | 6 | 6 | 12800.00 |
| FIN_CUSTOMER_029 | 6 | 6 | 12027.00 |
| FIN_CUSTOMER_019 | 5 | 5 | 201267.21 |
| FIN_CUSTOMER_020 | 5 | 5 | 74256.00 |


## Exercise 4 — CTE foundation: customer cumulative totals

**Question and conditions.** Create customer_totals with one row per customer and full-period SUM(transaction_amount) as total_amount. In the outer query return customer_id and total_amount, sorted total descending and customer ID ascending. No threshold applies.

**Row grain, example and interpretation.** WITH names an intermediate query result within one statement; it does not create a permanent stored table. Fictional example: amounts 4000 and 7000 for A form one A/11000 row. The actual output shown is an excerpt.

### Final query recorded in the journal

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
ORDER BY total_amount DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer\_id | total\_amount |
| --- | --- |
| FIN_CUSTOMER_030 | 1560034.99 |
| FIN_CUSTOMER_031 | 1380002.88 |
| FIN_CUSTOMER_032 | 991132.22 |


## Exercise 5 — CTE foundation: filter customer totals

**Question and conditions.** Build customer_totals across all transactions, then in the outer query retain customer_id and total_amount for totals of at least 10000, including the boundary. Sort amount descending then customer ID ascending.

**Row grain, example and interpretation.** Filtering the aggregate inside the CTE with HAVING was also numerically correct. The outer WHERE form practices treating an existing CTE column like a table column. The two displayed forms select the same customers; a change in placement is not evidence that the first calculation was wrong.

### Final query recorded in the journal

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
WHERE total_amount >= 10000
ORDER BY total_amount DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer\_id | total\_amount |
| --- | --- |
| FIN_CUSTOMER_030 | 1560034.99 |
| FIN_CUSTOMER_031 | 1380002.88 |
| FIN_CUSTOMER_032 | 991132.22 |


### Equivalent grouped filtering form

The following recorded form also selects the same customers; it is not an incorrect calculation.

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING total_amount >= 10000
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
ORDER BY total_amount DESC, customer_id ASC;
```

## Key concepts and next practice

Distinguish per-row conditions from aggregate conditions. Inside a grouped query, HAVING filters group results. In the outer query, total_amount already exists and WHERE filters its rows. The first CTE example and both threshold placements have recorded execution results. Window-function practice is covered in the next session.

Practice later without looking at the solution. This publication preserves recorded executions; it does not execute the exercise SQL or claim production experience.

## Audit notes — 2026-11-02

This session covers review plus CTE foundations, not completed window-function study. CTE results expose ordinary columns to the outer WHERE; repeating GROUP BY is unnecessary. A high-amount SUM changes which amounts are included, whereas an outer filter on a customer total selects customers after totaling all their transactions.

See the [full audit and scope notes](../../docs/audit.en.md).
