# Day 18 — Finance monthly metrics, distinct transaction days and subqueries

[한국어](../ko/day18.md) · [Index](../../README.md)

One bank_transactions row is one transaction. customer_id and transaction_date are non-NULL; transaction_date is DATE and transaction_amount is DECIMAL(15,2). The currency is not established. These exercises use the full table, not one month only. The SQL and result tables are transcribed from the Notion record; previously recorded database cross-checks are described there, not rerun for this publication.

## Tables and column types

bank_transactions: customer_id VARCHAR(20), transaction_date DATE, transaction_amount DECIMAL(15,2). One row is one transaction; the relevant fields are non-NULL.

## Exercise 1 — Monthly transaction statistics

**Question and conditions.** For each observed YYYY-MM, return transaction_month, transaction_count, total_transaction_amount and avg_transaction_amount. Count all transaction rows, sum their amounts and round the per-transaction mean to two decimals. Sort month ascending; no count or value threshold applies.

**Row grain, example and interpretation.** One row is one observed month. SUM retains the two-decimal precision of the amount column. Fictional example: four transactions totaling 10000 have a mean of 2500.

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


Recorded execution: 3 rows in set (1.21 sec).

## Exercise 2 — Monthly high-value transaction percentage

**Question and conditions.** For each observed month return transaction_month, transaction_count, high_amount_count and high_amount_rate. High value means amount at least 5000, including the boundary. Divide that count by all transactions in the month and multiply by 100, rounding to two decimals. Keep observed months with zero high-value transactions and show zero count/rate. Sort month ascending.

**Row grain, example and interpretation.** The conditional count and percentage numerator refer to the same transactions. Do not filter out other transactions before calculating the denominator. Fictional example: 20 qualifying rows among 200 gives 10%. No actual month in the recorded output had zero qualifying rows.

### Final query recorded in the journal

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;
```

### Recorded output (source excerpt)

| transaction\_month | transaction\_count | high\_amount\_count | high\_amount\_rate |
| --- | --- | --- | --- |
| 2016-08 | 653933 | 35767 | 5.47 |
| 2016-09 | 390975 | 21446 | 5.49 |
| 2016-10 | 3659 | 246 | 6.72 |


Recorded execution: 3 rows in set (1.40 sec).

## Exercise 3 — Customers active on at least three distinct dates

**Question and conditions.** For each customer return customer_id, transaction_count, active_day_count and total_transaction_amount. Count repeated dates once for active_day_count, while counting and summing all transactions. Keep at least three dates, not necessarily consecutive. Sort day count descending, total amount descending and customer ID ascending.

**Row grain, example and interpretation.** One result row is one selected customer. Three transactions on the same date are three transactions but one active day. The table is an excerpt, not a full result or five consecutive leading rows.

### Final query recorded in the journal

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT transaction_date) AS active_day_count,
    ROUND(SUM(transaction_amount), 2) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING active_day_count >= 3
ORDER BY active_day_count DESC, total_transaction_amount DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer\_id | transaction\_count | active\_day\_count | total\_transaction\_amount |
| --- | --- | --- | --- |
| FIN_CUSTOMER_027 | 6 | 6 | 14758.39 |
| FIN_CUSTOMER_028 | 6 | 6 | 12800.00 |
| FIN_CUSTOMER_029 | 6 | 6 | 12027.00 |
| FIN_CUSTOMER_018 | 6 | 6 | 9796.03 |
| FIN_CUSTOMER_007 | 6 | 5 | 37873.00 |


## Exercise 4 — Count customers active on at least three dates

**Question and conditions.** Count customers with transactions on at least three distinct dates across the full table. Repeated dates count once; exactly three qualifies and dates need not be consecutive. Return one customer_count row, zero if none qualify.

**Row grain, example and interpretation.** The inner result has one row per selected customer. The outer COUNT counts customer rows, not dates or transactions. The recorded result is 17685.

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT transaction_date) AS active_day_count,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING active_day_count >= 3
) AS active_customer_id;
```

### Recorded output (source excerpt)

| customer\_count |
| --- |
| 17685 |


Recorded execution: 1 row in set (2.12 sec).

## Exercise 5 — Mean cumulative amount for qualifying customers

**Question and conditions.** For customers with transactions on at least three distinct dates, calculate each full-period transaction total and then average those customer totals. Each customer has equal weight regardless of transaction/day count. Do not round intermediate totals; round only the final mean to two decimals as avg_customer_total.

**Row grain, example and interpretation.** The three-date condition selects customers; it is not a divisor. The result 4878.81 is a mean cumulative amount per selected customer, not per transaction or per active day.

### Final query recorded in the journal

```sql
SELECT ROUND(AVG(total_transaction_amount), 2) AS avg_customer_total
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT transaction_date) AS active_day_count,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING active_day_count >= 3
) AS active_customer;
```

### Recorded output (source excerpt)

| avg\_customer\_total |
| --- |
| 4878.81 |


Recorded execution: 1 row in set (1.75 sec).

## Key concepts and next practice

COUNT(*) counts rows. COUNT(date) excludes NULL but retains repeated dates; COUNT(DISTINCT date) also removes repeats. A derived-table name is not a numeric column: the outer AVG must read the customer-total column.

Practice later without looking at the solution. This publication preserves recorded executions; it does not execute the exercise SQL or claim production experience.

## Audit notes — 2026-11-02

Distinct transaction dates are active days because transaction_date is DATE. Counts of non-NULL dates do not deduplicate repeated transactions on the same date. Verification reproduced 17685 customers active on at least three distinct dates and a mean customer total of 4878.81.

See the [full audit and scope notes](../../docs/audit.en.md).
