# Day 12 — Customer aggregation and transaction distribution

[한국어](../ko/day12.md) · [Index](../../README.md)

Study date: 2026-10-10. Edited translation of every exercise, with historical SQL and source output excerpts; not rerun for publication.

Schema and row-grain details: [data notes](../../docs/data.en.md). Questions are custom practice exercises in a coding-platform format, not official Programmers or LeetCode problems.

Transaction customer IDs are publication pseudonyms, consistent within these two days.

## Exercise 1 — Active customers

**Question.** For each customer with at least five transactions, return transaction count, total amount and average amount rounded to two decimals. Sort by total descending, then customer ID ascending.

**Learning point.** Fix a misspelled amount column and align the COUNT alias with HAVING. The first query also omitted the five-transaction filter.

**Authorship and evidence.** Written by the learner, corrected with AI feedback; user-run output excerpts recorded.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id, COUNT(*) AS transaction,
       SUM(transaction_amount) AS total_transaction_amount,
       ROUND(AVG(transaction_amoiunt), 2) AS avg_transaction
FROM bank_transactions
GROUP BY customer_id
ORDER BY total_transaction_amount DESC, customer_id ASC;
```

### Final query recorded in the journal

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 5
ORDER BY total_transaction_amount DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | transaction_count | total_transaction_amount | avg_transaction_amount |
| --- | --- | --- | --- |
| FIN_CUSTOMER_019 | 5 | 201267.21 | 40253.44 |
| FIN_CUSTOMER_020 | 5 | 74256.00 | 14851.20 |
| FIN_CUSTOMER_025 | 5 | 38573.00 | 7714.60 |
| FIN_CUSTOMER_007 | 6 | 37873.00 | 6312.17 |

## Exercise 2 — Repeated transactions of at least 1,000

**Question.** Keep individual transactions worth at least 1,000, then return customers with at least three such transactions and their count and rounded mean. Sort count descending and ID ascending.

**Learning point.** Filtering a customer average in HAVING is different from filtering each transaction before grouping.

**Authorship and evidence.** Learner attempt corrected after feedback about WHERE, HAVING and sorting; user-run excerpts recorded.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id, COUNT(*) AS transaction_count,
       ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 3 AND avg_transaction_amount >= 1000
ORDER BY transaction_count DESC, avg_transaction_amount ASC;
```

### Final query recorded in the journal

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
WHERE transaction_amount >= 1000
GROUP BY customer_id
HAVING transaction_count >= 3
ORDER BY transaction_count DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | transaction_count | avg_transaction_amount |
| --- | --- | --- |
| FIN_CUSTOMER_006 | 4 | 8505.00 |
| FIN_CUSTOMER_012 | 4 | 1148.75 |
| FIN_CUSTOMER_015 | 4 | 1925.00 |
| FIN_CUSTOMER_016 | 4 | 1694.50 |

## Exercise 3 — High-value transaction counts

**Question.** For customers with at least five total transactions, return total count and the count worth at least 5,000. Include zero high-value counts; sort high-value count descending and ID ascending.

**Learning point.** A conditional count preserves other transactions; filtering the source to high-value rows would change the total.

**Authorship and evidence.** Learner attempt corrected with conditional-aggregation guidance; user-run output recorded.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id, COUNT(*) AS total_transaction_count, high_amount_count
FROM bank_transactions
(SELECT transaction_amount
 FROM bank_transactions
 WHERE transaction_amount >= 5000) AS amount_count
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_count DESC, customer_id ASC;
```

### Final query recorded in the journal

```sql
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_count DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | total_transaction_count | high_amount_count |
| --- | --- | --- |
| FIN_CUSTOMER_006 | 5 | 2 |
| FIN_CUSTOMER_014 | 5 | 2 |
| FIN_CUSTOMER_007 | 6 | 1 |
| FIN_CUSTOMER_005 | 6 | 0 |

## Exercise 4 — High-value transaction percentage

**Question.** For customers with at least five transactions, return total count, count worth at least 5,000 and the high-value percentage rounded to two decimals. Sort percentage descending and ID ascending.

**Learning point.** Use all customer transactions as the denominator. SUM of 1/0 flags and conditional COUNT can express the numerator with the stated null treatment.

**Authorship and evidence.** AI-assisted completion; source records available output, not an independent rewrite.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        SUM(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_rate DESC, customer_id ASC;
```

### Final query recorded in the journal

```sql
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        SUM(CASE WHEN transaction_amount >= 5000 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_rate DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | total_transaction_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| FIN_CUSTOMER_006 | 5 | 2 | 40.00 |
| FIN_CUSTOMER_007 | 6 | 1 | 16.67 |
| FIN_CUSTOMER_022 | 5 | 0 | 0.00 |

## Exercise 5 — Customer distribution by transaction count

**Question.** Count transactions per customer, then report how many customers have each transaction count. Sort transaction count ascending.

**Learning point.** The inner COUNT counts transaction rows; the outer COUNT counts customer rows.

**Authorship and evidence.** Learner inner query and attempted outer query; AI helped correct the outer grouping/selection. User execution recorded.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id, COUNT(*) AS transaction_count
FROM bank_transactions
GROUP BY customer_id
ORDER BY transaction_count DESC;
```

### Final query recorded in the journal

```sql
SELECT
    transaction_count,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count
    FROM bank_transactions
    GROUP BY customer_id
) AS customer_transactions
GROUP BY transaction_count
ORDER BY transaction_count ASC;
```

### Recorded output (source excerpt)

| transaction_count | customer_count |
| --- | --- |
| 1 | 740653 |
| 2 | 124960 |
| 3 | 16789 |
| 4 | 1702 |
| 5 | 147 |
| 6 | 14 |

| total_transactions | total_customers |
| --- | --- |
| 1048567 | 884265 |

