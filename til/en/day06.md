# Day 06 — Transaction aggregation and CASE WHEN

[한국어 원기록](../ko/day06.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Calculate the transaction count and total amount.

**Learning point.** An earlier alias described a transaction date instead of a count. Name outputs for what they measure.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    COUNT(*) transaction_date,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions;
```

### Final query recorded in the journal

```sql
SELECT
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions;
```

### Recorded output (source excerpt)

| transaction_count | total_transaction_amount |
| --- | --- |
| 1,048,567 | 1,650,795,731.57 |

## Exercise 2

**Question.** Calculate transaction count and total amount by transaction date, ascending.

**Learning point.** A missing calendar date does not by itself prove missing data; first establish expected coverage.

### Final query recorded in the journal

```sql
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY transaction_date;
```

### Recorded output (source excerpt)

| transaction_date | transaction_count | total_transaction_amount |
| --- | --- | --- |
| 2016-08-01 | 20,438 | 29,801,816.34 |
| 2016-08-02 | 20,948 | 30,467,503.29 |
| 2016-08-03 | 20,615 | 31,149,483.67 |
| 2016-08-04 | 20,682 | 35,722,718.64 |
| 2016-08-05 | 21,112 | 34,833,933.12 |
| ... | ... | ... |
| 2016-09-30 | 1,951 | 3,316,668.50 |
| 2016-10-16 | 3 | 1,067.00 |
| 2016-10-21 | 3,656 | 7,663,951.63 |

## Exercise 3

**Question.** Calculate daily count, total and average transaction amount, rounding the average to two decimals and sorting by average descending.

**Learning point.** AVG measures average transaction size, not total activity.

### Final query recorded in the journal

```sql
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY avg_transaction_amount DESC;
```

### Recorded output (source excerpt)

| transaction_date | transaction_count | total_transaction_amount | avg_transaction_amount |
| --- | --- | --- | --- |
| 2016-10-21 | 3,656 | 7,663,951.63 | 2,096.27 |
| 2016-08-15 | 24,171 | 44,313,092.06 | 1,833.32 |
| 2016-09-22 | 6,971 | 12,746,612.34 | 1,828.52 |
| 2016-08-06 | 26,585 | 47,527,227.82 | 1,787.75 |
| 2016-08-14 | 25,596 | 45,732,820.10 | 1,786.72 |

## Exercise 4

**Question.** Find customers with at least five transactions, ordered by count and then amount descending.

**Learning point.** Group by customer_id, not by an aggregate count. Published customer identifiers are consistently pseudonymized.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_count
HAVING transaction_count >= 5
ORDER BY total_transaction_amount ASC, transaction_count DESC;
```

### Final query recorded in the journal

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 5
ORDER BY
    transaction_count DESC,
    total_transaction_amount DESC;
```

### Recorded output (source excerpt)

| customer_id | transaction_count | total_transaction_amount |
| --- | --- | --- |
| CUSTOMER_001 | 6 | 37,873.00 |
| CUSTOMER_010 | 6 | 21,597.50 |
| CUSTOMER_002 | 6 | 14,758.39 |
| CUSTOMER_005 | 6 | 12,800.00 |
| CUSTOMER_004 | 6 | 12,027.00 |
| CUSTOMER_003 | 6 | 9,796.03 |
| CUSTOMER_007 | 6 | 8,503.00 |
| CUSTOMER_009 | 6 | 8,375.74 |
| CUSTOMER_008 | 6 | 5,825.00 |
| CUSTOMER_006 | 6 | 5,722.78 |

## Exercise 5

**Question.** Classify transactions as Small below 1,000, Medium from 1,000 to below 5,000, and Large at least 5,000; calculate count and total per band.

**Learning point.** CASE needs THEN and END. Check boundaries and null handling. The source records a category-count reconciliation to 1,048,567 transactions.

### Final query recorded in the journal

```sql
SELECT
    CASE
        WHEN transaction_amount < 1000 THEN 'Small'
        WHEN transaction_amount >= 1000
             AND transaction_amount < 5000 THEN 'Medium'
        WHEN transaction_amount >= 5000 THEN 'Large'
    END AS amount_category,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY amount_category
ORDER BY transaction_count DESC;
```

### Recorded output (source excerpt)

| amount_category | transaction_count | total_transaction_amount |
| --- | --- | --- |
| Small | 728,139 | 228,135,223.55 |
| Medium | 262,969 | 532,506,983.51 |
| Large | 57,459 | 890,153,524.51 |

