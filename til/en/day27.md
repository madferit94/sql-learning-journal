# Day 27 — Finance month-over-month and previous active-date comparisons

[한국어](../ko/day27.md) · [Index](../../README.md) · [SQL](../../sql/day27.sql)

MySQL / finance. Each bank_transactions row is one transaction. The three source columns used here are NOT NULL. Result NULLs indicate either no earlier comparison row or an undefined change rate.

| Column | Type | Meaning |
| --- | --- | --- |
| customer_id | VARCHAR(20) | Customer ID |
| transaction_date | DATE | Transaction date |
| transaction_amount | DECIMAL(15,2) | Transaction amount (source units) |

Connect from the shell, then choose the database at the mysql> prompt.

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

```sql
USE finance;
```

Customer IDs in public tables are pseudonymized consistently across all tables.

## Exercise 1 — Question 1: Monthly transaction and customer counts

Show one row per observed month in ascending YYYY-MM order. Count all transaction rows, distinct customer IDs within the month, and sum all amounts. In a hypothetical example, A transacts 100 and 200 and B transacts 300: 3 transactions, 2 customers, 600.00 total.

### Final query recorded in the journal

```sql
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       COUNT(*) AS transaction_count,
       COUNT(DISTINCT customer_id) AS customer_count,
       SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month;
```

### Recorded output

| transaction_month | transaction_count | customer_count | total_transaction_amount |
| --- | --- | --- | --- |
| 2016-08 | 653933 | 586592 | 1030599493.84 |
| 2016-09 | 390975 | 366148 | 612531219.10 |
| 2016-10 | 3659 | 3654 | 7665018.63 |

## Exercise 2 — Question 2: Monthly amount change

Return each monthly total, the previous observed month’s total and current minus previous. Use NULL for both comparison fields on the first row and sort by month ascending. Hypothetical example: 600 → 450 gives -150.00. LAG reads the previous ordered row; the observed months here are consecutive.

### Final query recorded in the journal

```sql
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       SUM(transaction_amount) AS total_transaction_amount,
       LAG(SUM(transaction_amount)) OVER (
           ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')
       ) AS previous_month_amount,
       SUM(transaction_amount) - LAG(SUM(transaction_amount)) OVER (
           ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')
       ) AS amount_change
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month;
```

### Recorded output

| transaction_month | total_transaction_amount | previous_month_amount | amount_change |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | NULL | NULL |
| 2016-09 | 612531219.10 | 1030599493.84 | -418068274.74 |
| 2016-10 | 7665018.63 | 612531219.10 | -604866200.47 |

## Exercise 3 — Question 3-1: Main answer: two CTEs and NULLIF

Return monthly amount, previous amount, and (current − previous) ÷ previous × 100. Round only the percentage to two decimals and sort by month ascending. The first rate and rates with a zero denominator are NULL. Hypothetical example: 600 → 450 gives -25.00%.

Build monthly totals and previous amounts in sequence. No outer GROUP BY is needed because the first CTE already gives one row per month. NULLIF converts a zero denominator to NULL.

### Final query recorded in the journal

```sql
WITH month_amount AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
           SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY transaction_month
),
lag_amount AS (
    SELECT transaction_month, total_transaction_amount,
           LAG(total_transaction_amount) OVER (
               ORDER BY transaction_month
           ) AS previous_month_amount
    FROM month_amount
)
SELECT transaction_month, total_transaction_amount, previous_month_amount,
       ROUND((total_transaction_amount - previous_month_amount)
             / NULLIF(previous_month_amount, 0) * 100, 2) AS amount_change_rate
FROM lag_amount
ORDER BY transaction_month;
```

### Recorded output

| transaction_month | total_transaction_amount | previous_month_amount | amount_change_rate |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | NULL | NULL |
| 2016-09 | 612531219.10 | 1030599493.84 | -40.57 |
| 2016-10 | 7665018.63 | 612531219.10 | -98.75 |

## Exercise 4 — Question 3-2: Alternative: named WINDOW without a CTE

Return monthly amount, previous amount, and (current − previous) ÷ previous × 100. Round only the percentage to two decimals and sort by month ascending. The first rate and rates with a zero denominator are NULL. Hypothetical example: 600 → 450 gives -25.00%.

WINDOW month_order AS (ORDER BY MIN(transaction_date)) names the window ordering. It uses the earliest transaction date in each month and is reused through OVER month_order. It reuses the rule, not the value returned by LAG. The last ORDER BY controls display order. All three observed output rows matched the main answer.

### Final query recorded in the journal

```sql
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       SUM(transaction_amount) AS total_transaction_amount,
       LAG(SUM(transaction_amount)) OVER month_order AS previous_month_amount,
       ROUND(
           (SUM(transaction_amount) - LAG(SUM(transaction_amount)) OVER month_order)
           / NULLIF(LAG(SUM(transaction_amount)) OVER month_order, 0) * 100,
           2
       ) AS amount_change_rate
FROM finance.bank_transactions
GROUP BY transaction_month
WINDOW month_order AS (ORDER BY MIN(transaction_date))
ORDER BY transaction_month;
```

### Recorded output

| transaction_month | total_transaction_amount | previous_month_amount | amount_change_rate |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | NULL | NULL |
| 2016-09 | 612531219.10 | 1030599493.84 | -40.57 |
| 2016-10 | 7665018.63 | 612531219.10 | -98.75 |

## Exercise 5 — Question 3-3: Display variant: use IFNULL to show 0.00

Return monthly amount, previous amount, and (current − previous) ÷ previous × 100. Round only the percentage to two decimals and sort by month ascending. The first rate and rates with a zero denominator are NULL. Hypothetical example: 600 → 450 gives -25.00%.

Keep the original previous amount and the NULLIF denominator for calculation. Wrap each output in IFNULL only in the final SELECT. This can make unavailable comparisons look the same as a real 0% change, so it is separate from the original answer. The table is from a separate verification run.

### Final query recorded in the journal

```sql
WITH month_amount AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
           SUM(transaction_amount) AS total_transaction_amount
    FROM finance.bank_transactions
    GROUP BY transaction_month
),
lag_amount AS (
    SELECT transaction_month, total_transaction_amount,
           LAG(total_transaction_amount) OVER (
               ORDER BY transaction_month
           ) AS previous_month_amount
    FROM month_amount
)
SELECT transaction_month, total_transaction_amount,
       IFNULL(previous_month_amount, 0.00) AS previous_month_amount,
       IFNULL(ROUND((total_transaction_amount - previous_month_amount)
                    / NULLIF(previous_month_amount, 0) * 100, 2), 0.00) AS amount_change_rate
FROM lag_amount
ORDER BY transaction_month;
```

### Follow-up verification

| transaction_month | total_transaction_amount | previous_month_amount | amount_change_rate |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | 0.00 | 0.00 |
| 2016-09 | 612531219.10 | 1030599493.84 | -40.57 |
| 2016-10 | 7665018.63 | 612531219.10 | -98.75 |

## Exercise 6 — Question 4-1: Submitted query: DATE_FORMAT

Sum all transactions for each customer and date, then attach the same customer’s most recent earlier active date’s total. The first active date has NULL. Sort by customer ID and date ascending and return the first 20 rows. Hypothetical example: A trades on August 3 and 7, so August 7 reads August 3’s total.

The 20 output rows were correct. SHOW WARNINGS reported 1052: Column 'transaction_date' in group statement is ambiguous. The GROUP BY name matched both the source column and the DATE_FORMAT alias.

### Final query recorded in the journal

```sql
WITH customer_daily_amount AS (
    SELECT customer_id,
           DATE_FORMAT(transaction_date, '%Y-%m-%d') AS transaction_date,
           SUM(transaction_amount) AS daily_amount
    FROM bank_transactions
    GROUP BY customer_id, transaction_date
)
SELECT customer_id, transaction_date, daily_amount,
       LAG(daily_amount) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_day_amount
FROM customer_daily_amount
ORDER BY customer_id, transaction_date
LIMIT 20;
```

### Recorded output

| customer_id | transaction_date | daily_amount | previous_day_amount |
| --- | --- | --- | --- |
| customer_01 | 2016-08-09 | 356.00 | NULL |
| customer_01 | 2016-09-26 | 4750.00 | 356.00 |
| customer_02 | 2016-08-14 | 1499.00 | NULL |
| customer_03 | 2016-08-01 | 1205.00 | NULL |
| customer_03 | 2016-08-07 | 250.00 | 1205.00 |
| customer_04 | 2016-09-15 | 30.00 | NULL |
| customer_05 | 2016-08-18 | 5000.00 | NULL |
| customer_06 | 2016-08-29 | 557.00 | NULL |
| customer_07 | 2016-08-03 | 404.00 | NULL |
| customer_07 | 2016-08-04 | 1460.00 | 404.00 |
| customer_08 | 2016-08-01 | 50.00 | NULL |
| customer_08 | 2016-08-27 | 700.00 | 50.00 |
| customer_09 | 2016-08-26 | 208.00 | NULL |
| customer_10 | 2016-08-09 | 19680.00 | NULL |
| customer_11 | 2016-09-07 | 100.00 | NULL |
| customer_12 | 2016-09-02 | 915.00 | NULL |
| customer_13 | 2016-08-06 | 2397.00 | NULL |
| customer_13 | 2016-09-07 | 20.00 | 2397.00 |
| customer_13 | 2016-09-10 | 14500.00 | 20.00 |
| customer_14 | 2016-08-18 | 201.00 | NULL |

## Exercise 7 — Question 4-2: Alternative: keep the DATE column

Sum all transactions for each customer and date, then attach the same customer’s most recent earlier active date’s total. The first active date has NULL. Sort by customer ID and date ascending and return the first 20 rows. Hypothetical example: A trades on August 3 and 7, so August 7 reads August 3’s total.

The source is already DATE, so grouping and sorting require no formatting. All 20 rows matched the submitted query, and the alternative produced no warnings.

### Final query recorded in the journal

```sql
WITH customer_daily_amount AS (
    SELECT customer_id, transaction_date, SUM(transaction_amount) AS daily_amount
    FROM finance.bank_transactions
    GROUP BY customer_id, transaction_date
)
SELECT customer_id, transaction_date, daily_amount,
       LAG(daily_amount) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_day_amount
FROM customer_daily_amount
ORDER BY customer_id, transaction_date
LIMIT 20;
```

### Recorded output

| customer_id | transaction_date | daily_amount | previous_day_amount |
| --- | --- | --- | --- |
| customer_01 | 2016-08-09 | 356.00 | NULL |
| customer_01 | 2016-09-26 | 4750.00 | 356.00 |
| customer_02 | 2016-08-14 | 1499.00 | NULL |
| customer_03 | 2016-08-01 | 1205.00 | NULL |
| customer_03 | 2016-08-07 | 250.00 | 1205.00 |
| customer_04 | 2016-09-15 | 30.00 | NULL |
| customer_05 | 2016-08-18 | 5000.00 | NULL |
| customer_06 | 2016-08-29 | 557.00 | NULL |
| customer_07 | 2016-08-03 | 404.00 | NULL |
| customer_07 | 2016-08-04 | 1460.00 | 404.00 |
| customer_08 | 2016-08-01 | 50.00 | NULL |
| customer_08 | 2016-08-27 | 700.00 | 50.00 |
| customer_09 | 2016-08-26 | 208.00 | NULL |
| customer_10 | 2016-08-09 | 19680.00 | NULL |
| customer_11 | 2016-09-07 | 100.00 | NULL |
| customer_12 | 2016-09-02 | 915.00 | NULL |
| customer_13 | 2016-08-06 | 2397.00 | NULL |
| customer_13 | 2016-09-07 | 20.00 | 2397.00 |
| customer_13 | 2016-09-10 | 14500.00 | 20.00 |
| customer_14 | 2016-08-18 | 201.00 | NULL |

## Exercise 8 — Question 5: Customers with at least two increase days

Using all data, sum by customer and active date, then count dates when the amount strictly exceeded the same customer’s previous active date. Exclude first dates and ties. Keep customers with at least two increase days, sort by count descending then customer ID ascending, and output the first 20 rows. Hypothetical example: 100 → 150 → 120 → 200 has two increase days.

The condition counts only strict increases: neither a NULL previous value nor a tie is counted. The recorded maximum is four increase days.

### Final query recorded in the journal

```sql
WITH customer_daily_amount AS (
    SELECT customer_id, transaction_date, SUM(transaction_amount) AS daily_amount
    FROM finance.bank_transactions
    GROUP BY customer_id, transaction_date
),
prev_amount AS (
    SELECT customer_id, transaction_date, daily_amount,
           LAG(daily_amount) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           ) AS previous_day_amount
    FROM customer_daily_amount
)
SELECT customer_id,
       COUNT(CASE WHEN previous_day_amount < daily_amount THEN 1 END) AS increase_day_count
FROM prev_amount
GROUP BY customer_id
HAVING increase_day_count >= 2
ORDER BY increase_day_count DESC, customer_id
LIMIT 20;
```

### Recorded output

| customer_id | increase_day_count |
| --- | --- |
| customer_31 | 4 |
| customer_15 | 3 |
| customer_16 | 3 |
| customer_17 | 3 |
| customer_18 | 3 |
| customer_19 | 3 |
| customer_20 | 3 |
| customer_21 | 3 |
| customer_22 | 3 |
| customer_23 | 3 |
| customer_24 | 3 |
| customer_25 | 3 |
| customer_26 | 3 |
| customer_27 | 3 |
| customer_28 | 3 |
| customer_29 | 3 |
| customer_30 | 3 |
| customer_32 | 3 |
| customer_33 | 3 |
| customer_34 | 3 |

## Review

Monthly aggregation yields one row per month; daily aggregation yields one row per customer and active date. LAG ordering determines the previous row; final ordering determines display. Inactive dates are absent. Periods can contain different amounts of observed data, so a drop in monthly totals does not establish a change in customer behavior.
