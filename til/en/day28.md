# Day 28 — Finance transaction gaps and long-gap share

[한국어](../ko/day28.md) · [Index](../../README.md) · [SQL](../../sql/day28.sql)

MySQL 8.4 / finance.bank_transactions. Each row is a transaction. The columns used are customer_id (VARCHAR(20)) and transaction_date (DATE), both NOT NULL. Public output tables use consistent customer pseudonyms.

## Exercise 1 — Question 1: Customer transaction gaps

Show one row for each customer and active transaction date: the current date, that customer’s previous active date, and the days between them. Count a date only once even if the customer made several transactions that day. The first date has NULL for both comparison fields. Sort by customer ID and current date ascending and show the first 20 rows. Hypothetical example: August 3 to August 7 is four days. LAG retrieves the preceding date; DATEDIFF measures elapsed calendar days.

### Final query recorded in the journal

```sql
WITH customer_dates AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
)
SELECT customer_id, transaction_date,
       LAG(transaction_date) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_transaction_date,
       DATEDIFF(transaction_date, LAG(transaction_date) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       )) AS days_since_previous
FROM customer_dates
ORDER BY customer_id ASC, transaction_date ASC
LIMIT 20;
```

### Recorded output (excerpt)

| customer_id | transaction_date | previous_transaction_date | days_since_previous |
| --- | --- | --- | --- |
| customer_01 | 2016-08-09 | NULL | NULL |
| customer_01 | 2016-09-26 | 2016-08-09 | 48 |
| customer_02 | 2016-08-14 | NULL | NULL |

## Exercise 2 — Question 2: Average gap by customer

For customers who transacted on at least three distinct dates, show the number of active dates and the average gap between consecutive active dates. The first date counts as an active date but does not contribute a gap. Use the complete dataset, sort by the unrounded average descending then customer ID ascending, and show the first 20 rows. Round the displayed average to two decimal places. Hypothetical example: NULL, 4, and 9 means three dates and an average of 6.50 days over two gaps.

### Final query recorded in the journal

```sql
WITH active_day AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_days AS (
    SELECT customer_id,
           DATEDIFF(transaction_date, LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           )) AS days_since_previous
    FROM active_day
)
SELECT customer_id, COUNT(*) AS active_day_count,
       ROUND(AVG(days_since_previous), 2) AS avg_days_between_transactions
FROM prev_days
GROUP BY customer_id
HAVING active_day_count >= 3
ORDER BY AVG(days_since_previous) DESC, customer_id
LIMIT 20;
```

### Recorded output (excerpt)

| customer_id | active_day_count | avg_days_between_transactions |
| --- | --- | --- |
| customer_04 | 3 | 40.50 |
| customer_07 | 3 | 40.50 |
| customer_06 | 3 | 40.00 |

## Exercise 3 — Question 3: Returns after a gap of 30 days or more

Show each customer-date where at least 30 days passed since that customer’s previous active date. A 30-day gap qualifies; the first date does not. Sort by gap descending, then customer ID and current date ascending, and show the first 20 rows. Hypothetical example: August 5 to September 4 is a qualifying gap of 30 days. The final filter keeps qualifying dates as separate rows.

### Final query recorded in the journal

```sql
WITH active_day AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_days AS (
    SELECT customer_id, transaction_date,
           LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           ) AS previous_transaction_date
    FROM active_day
)
SELECT customer_id, transaction_date, previous_transaction_date,
       DATEDIFF(transaction_date, previous_transaction_date) AS days_since_previous
FROM prev_days
WHERE DATEDIFF(transaction_date, previous_transaction_date) >= 30
ORDER BY days_since_previous DESC, customer_id ASC, transaction_date ASC
LIMIT 20;
```

### Recorded output (excerpt)

| customer_id | transaction_date | previous_transaction_date | days_since_previous |
| --- | --- | --- | --- |
| customer_03 | 2016-10-21 | 2016-08-01 | 81 |
| customer_09 | 2016-10-21 | 2016-08-01 | 81 |
| customer_11 | 2016-10-21 | 2016-08-02 | 80 |

## Exercise 4 — Question 4: Customers with at least two gaps of 30 days or more

Count qualifying gaps and find the longest one for each customer with at least two qualifying gaps. Use the complete dataset. Sort by qualifying count descending, longest gap descending, then customer ID ascending, and show the first 20 rows. Hypothetical example: NULL, 30, 9, and 41 yields two qualifying gaps and a maximum of 41 days. The source alias previous_date here holds the gap in days, not a date.

### Final query recorded in the journal

```sql
WITH active_customer AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_day AS (
    SELECT customer_id, transaction_date,
           DATEDIFF(transaction_date, LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           )) AS previous_date
    FROM active_customer
)
SELECT customer_id, COUNT(previous_date) AS long_gap_count,
       MAX(previous_date) AS longest_gap_days
FROM prev_day
WHERE previous_date >= 30
GROUP BY customer_id
HAVING long_gap_count >= 2
ORDER BY long_gap_count DESC, longest_gap_days DESC, customer_id ASC
LIMIT 20;
```

### Recorded output (excerpt)

| customer_id | long_gap_count | longest_gap_days |
| --- | --- | --- |
| customer_20 | 2 | 50 |
| customer_15 | 2 | 48 |
| customer_28 | 2 | 47 |

## Exercise 5 — Question 5-1: Long-gap share: with NULLIF

For each customer, go through their distinct active dates in order. Skip the first date because there’s no earlier date to compare it with. On every later date, calculate how many days passed since their previous transaction date. Of all those gaps, what percentage lasted 30 days or longer?

Include customers with at least three distinct active dates, including those with zero qualifying gaps. Shorter gaps still count in the denominator. Use the complete dataset. Sort by the unrounded rate descending, then the number of long gaps descending, then customer ID ascending. Show the first 20 rows and round the displayed rate to two decimals.

| Output column | Meaning |
| --- | --- |
| customer_id | Customer ID |
| total_gap_count | All gaps you can compare; the first date has no gap |
| long_gap_count | Gaps of at least 30 days |
| long_gap_rate | Long gaps ÷ all comparable gaps × 100 |

**Hypothetical example:** Suppose a customer's gaps are 30, 9, and 41 days. The 9-day gap still counts toward the total. Two of three gaps lasted at least 30 days, so the rate is **66.67%**. If none of a customer's comparable gaps qualify, the rate is **0.00%**.

**Why use NULLIF?** NULLIF(a, b) returns NULL when the values are equal and a otherwise. NULLIF(total_gap_count, 0) turns a zero denominator into NULL, avoiding division by zero if the eligibility rule later includes customers with only one active date. No comparable gaps means an undefined rate (NULL); comparable gaps with no long gaps means 0.00%. With the current rule, both versions return the same results.

### Final query recorded in the journal

```sql
WITH customer_date AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM finance.bank_transactions
),
prev_day AS (
    SELECT
        customer_id,
        transaction_date,
        LAG(transaction_date) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_date
    FROM customer_date
),
gap_count AS (
    SELECT
        customer_id,
        COUNT(previous_date) AS total_gap_count,
        COUNT(
            CASE WHEN DATEDIFF(transaction_date, previous_date) >= 30
                 THEN 1
            END
        ) AS long_gap_count
    FROM prev_day
    GROUP BY customer_id
    HAVING COUNT(*) >= 3
)
SELECT
    customer_id,
    total_gap_count,
    long_gap_count,
    ROUND(long_gap_count / NULLIF(total_gap_count, 0) * 100, 2) AS long_gap_rate
FROM gap_count
ORDER BY long_gap_count / NULLIF(total_gap_count, 0) DESC,
         long_gap_count DESC,
         customer_id ASC
LIMIT 20;
```

### Recorded output

| customer_id | total_gap_count | long_gap_count | long_gap_rate |
| --- | --- | --- | --- |
| customer_05 | 2 | 2 | 100.00 |
| customer_06 | 2 | 2 | 100.00 |
| customer_08 | 2 | 2 | 100.00 |
| customer_10 | 2 | 2 | 100.00 |
| customer_12 | 2 | 2 | 100.00 |
| customer_13 | 2 | 2 | 100.00 |
| customer_14 | 2 | 2 | 100.00 |
| customer_15 | 2 | 2 | 100.00 |
| customer_16 | 2 | 2 | 100.00 |
| customer_17 | 2 | 2 | 100.00 |
| customer_18 | 2 | 2 | 100.00 |
| customer_19 | 2 | 2 | 100.00 |
| customer_20 | 2 | 2 | 100.00 |
| customer_21 | 2 | 2 | 100.00 |
| customer_22 | 2 | 2 | 100.00 |
| customer_23 | 2 | 2 | 100.00 |
| customer_24 | 2 | 2 | 100.00 |
| customer_25 | 2 | 2 | 100.00 |
| customer_26 | 2 | 2 | 100.00 |
| customer_27 | 2 | 2 | 100.00 |

Both versions returned the same 20 rows in the same order. Individual runtimes do not establish a performance difference.

## Exercise 6 — Question 5-2: Long-gap share: without NULLIF

Use the same question, columns, and sorting as in Question 5-1. Here the three-date minimum guarantees at least two gaps, so the denominator cannot be zero.

### Final query recorded in the journal

```sql
WITH customer_date AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM finance.bank_transactions
),
prev_day AS (
    SELECT
        customer_id,
        transaction_date,
        LAG(transaction_date) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_date
    FROM customer_date
),
gap_count AS (
    SELECT
        customer_id,
        COUNT(previous_date) AS total_gap_count,
        COUNT(
            CASE WHEN DATEDIFF(transaction_date, previous_date) >= 30
                 THEN 1
            END
        ) AS long_gap_count
    FROM prev_day
    GROUP BY customer_id
    HAVING COUNT(*) >= 3
)
SELECT
    customer_id,
    total_gap_count,
    long_gap_count,
    ROUND(long_gap_count / total_gap_count * 100, 2) AS long_gap_rate
FROM gap_count
ORDER BY long_gap_count / total_gap_count DESC,
         long_gap_count DESC,
         customer_id ASC
LIMIT 20;
```

### Recorded output

| customer_id | total_gap_count | long_gap_count | long_gap_rate |
| --- | --- | --- | --- |
| customer_05 | 2 | 2 | 100.00 |
| customer_06 | 2 | 2 | 100.00 |
| customer_08 | 2 | 2 | 100.00 |
| customer_10 | 2 | 2 | 100.00 |
| customer_12 | 2 | 2 | 100.00 |
| customer_13 | 2 | 2 | 100.00 |
| customer_14 | 2 | 2 | 100.00 |
| customer_15 | 2 | 2 | 100.00 |
| customer_16 | 2 | 2 | 100.00 |
| customer_17 | 2 | 2 | 100.00 |
| customer_18 | 2 | 2 | 100.00 |
| customer_19 | 2 | 2 | 100.00 |
| customer_20 | 2 | 2 | 100.00 |
| customer_21 | 2 | 2 | 100.00 |
| customer_22 | 2 | 2 | 100.00 |
| customer_23 | 2 | 2 | 100.00 |
| customer_24 | 2 | 2 | 100.00 |
| customer_25 | 2 | 2 | 100.00 |
| customer_26 | 2 | 2 | 100.00 |
| customer_27 | 2 | 2 | 100.00 |

Both versions returned the same 20 rows in the same order. Individual runtimes do not establish a performance difference.

## Review

Question 3 keeps qualifying date rows. Question 4 aggregates those qualifying date rows by customer. Question 5 counts long gaps conditionally while retaining all comparable gaps for the denominator.
