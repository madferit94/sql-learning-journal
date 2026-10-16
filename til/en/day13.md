# Day 13 — Conditional counts, amounts and customer totals

[한국어](../ko/day13.md) · [Index](../../README.md)

Study date: 2026-10-11. Edited translation of every exercise, with historical SQL and source output excerpts; not rerun for publication.

Schema and row-grain details: [data notes](../../docs/data.en.md). Questions are custom practice exercises in a coding-platform format, not official Programmers or LeetCode problems.

Transaction customer IDs are publication pseudonyms, consistent within these two days.

## Exercise 1 — Customers with multiple high-value transactions

**Question.** For each customer with at least two transactions worth at least 5,000, return their count and amount total. Sort amount total descending, then ID ascending.

**Learning point.** SUM must receive the transaction amount, not 1. HAVING must filter the high-value count.

**Authorship and evidence.** AI feedback on conditional SUM and HAVING; learner executed the corrected query.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    SUM(CASE WHEN transaction_amount >= 5000 THEN 1 ELSE 0 END) AS high_amount_total
FROM bank_transactions
GROUP BY customer_id
ORDER BY high_amount_total DESC, customer_id ASC;
```

### Final query recorded in the journal

```sql
SELECT customer_id,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    SUM(CASE WHEN transaction_amount >= 5000 THEN transaction_amount ELSE 0 END) AS high_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING high_amount_count >= 2
ORDER BY high_amount_total DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | high_amount_count | high_amount_total |
| --- | --- | --- |
| FIN_CUSTOMER_021 | 2 | 317471.25 |
| FIN_CUSTOMER_017 | 2 | 309093.00 |
| FIN_CUSTOMER_026 | 2 | 205029.12 |
| FIN_CUSTOMER_010 | 2 | 200000.00 |
| FIN_CUSTOMER_019 | 2 | 200000.00 |

## Exercise 2 — Total and small-value transactions

**Question.** For customers with at least five total transactions, return total count and count/sum of transactions below 1,000. Include zero small-value results; sort small count descending then ID ascending.

**Learning point.** A bare WHEN amount is a truth-value test, not a small-transaction condition. Apply the threshold to the conditional SUM too.

**Authorship and evidence.** Learner corrected COUNT and conditional SUM with AI guidance; user-run excerpts recorded.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id,
    COUNT(CASE WHEN transaction_amount THEN 1 END) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    SUM(CASE WHEN transaction_amount THEN transaction_amount ELSE 0 END) AS small_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_count DESC, customer_id ASC;
```

### Final query recorded in the journal

```sql
SELECT customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    SUM(CASE WHEN transaction_amount < 1000 THEN transaction_amount ELSE 0 END) AS small_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_count DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | total_transaction_count | small_amount_count | small_amount_total |
| --- | --- | --- | --- |
| FIN_CUSTOMER_005 | 6 | 5 | 2091.00 |
| FIN_CUSTOMER_008 | 5 | 5 | 1826.00 |
| FIN_CUSTOMER_009 | 5 | 5 | 1322.00 |
| FIN_CUSTOMER_023 | 6 | 5 | 525.00 |

## Exercise 3 — Small-value transaction percentage

**Question.** For customers with at least five transactions, return the count below 1,000 and its percentage of all transactions, rounded to two decimals. Include zeros; sort percentage descending then ID ascending.

**Learning point.** Do not filter away non-small transactions before calculating the denominator.

**Authorship and evidence.** First submitted query accepted without correction; prior-code reference was not independently checked.

### Final query recorded in the journal

```sql
SELECT customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    ROUND(
        COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) / COUNT(*) * 100,
        2
    ) AS small_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_rate DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | total_transaction_count | small_amount_count | small_amount_rate |
| --- | --- | --- | --- |
| FIN_CUSTOMER_008 | 5 | 5 | 100.00 |
| FIN_CUSTOMER_009 | 5 | 5 | 100.00 |
| FIN_CUSTOMER_011 | 5 | 5 | 100.00 |
| FIN_CUSTOMER_013 | 5 | 5 | 100.00 |

## Exercise 4 — Average customer total

**Question.** Calculate each customer's total transaction amount, then the mean of those totals. Round only the final result to two decimals.

**Learning point.** A customer total requires SUM, not COUNT; the outer AVG reads customer totals.

**Authorship and evidence.** AI helped replace COUNT with SUM and supplied the outer template; learner filled the AVG operand and executed it. Result: 1866.86.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id, COUNT(*) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id;
```

### Final query recorded in the journal

```sql
SELECT ROUND(AVG(total_transaction_amount), 2) AS avg_customer_total
FROM (
    SELECT customer_id,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
) AS customer_totals;
```

### Recorded output (source excerpt)

| avg_customer_total |
| --- |
| 1866.86 |

## Exercise 5 — Customers with totals of at least 10,000

**Question.** Count customers whose cumulative transaction amount across all periods is at least 10,000. Return one row.

**Learning point.** Filter customer totals inside the grouped query, then count the resulting customer rows.

**Authorship and evidence.** Inner SUM and HAVING written by learner; outer template provided by AI. Result: 26455. Full independent rewrite not established.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id, SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_amount >= 10000;
```

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT customer_id,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING total_transaction_amount >= 10000
) AS qualifying_customers;
```

### Recorded output (source excerpt)

| customer_count |
| --- |
| 26455 |

