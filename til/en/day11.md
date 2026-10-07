# Day 11 — Conditional aggregation and subquery review

[한국어 원기록](../ko/day11.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Count delivered orders purchased in 2017 by state, keeping at least one thousand and sorting count descending then state ascending.

**Learning point.** The first attempt omitted ORDER BY. Compare YEAR's numeric result with the numeric year.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    c.customer_state,
    COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = '2017'
  AND o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING delivered_order_count >= 1000;
```

### Final query recorded in the journal

```sql
SELECT
    c.customer_state,
    COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2017
  AND o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING delivered_order_count >= 1000
ORDER BY
    delivered_order_count DESC,
    customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | delivered_order_count |
| --- | --- |
| SP | 17071 |
| RJ | 5968 |
| MG | 5240 |
| RS | 2591 |
| PR | 2192 |
| SC | 1653 |
| BA | 1527 |

## Exercise 2

**Question.** For 2018 purchases, show order counts and distinct customer counts by state, keeping at least one thousand distinct customers and sorting by customer count descending then state ascending.

**Learning point.** Correct the year condition and use DISTINCT for the real-customer identifier.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    c.customer_state,
    COUNT(*) AS order_count,
    COUNT(customer_unique_id) AS customer_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(order_purchase_timestamp) = 2017
GROUP BY c.customer_state
HAVING customer_count >= 1000
ORDER BY
    customer_count DESC,
    customer_state ASC;
```

### Final query recorded in the journal

```sql
SELECT
    c.customer_state,
    COUNT(*) AS order_count,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING customer_count >= 1000
ORDER BY
    customer_count DESC,
    customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | order_count | customer_count |
| --- | --- | --- |
| SP | 23871 | 23289 |
| RJ | 6571 | 6400 |
| MG | 6181 | 6042 |
| RS | 2780 | 2715 |
| PR | 2755 | 2698 |
| SC | 1906 | 1868 |
| BA | 1784 | 1741 |
| DF | 1213 | 1182 |
| ES | 1061 | 1039 |
| GO | 1056 | 1030 |

## Exercise 3

**Question.** For 2018 purchases, show each state's total, delivered and canceled order counts, keeping at least one thousand total orders.

**Learning point.** The first attempt omitted THEN and filtered the wrong aggregate. The last recorded query still produced ERROR 1064, attributed in the notes to unusual whitespace. No successful final result is recorded; diagnosis has not been reverified.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    c.customer_state,
    COUNT(*) AS total_order_count,
    COUNT(CASE WHEN order_status = 'delivered' END) AS delivered_count,
    COUNT(CASE WHEN order_status = 'canceled' END) AS canceled_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING canceled_count >= 1000
ORDER BY
    total_order_count DESC,
    customer_state ASC;
```

### Last recorded query — unresolved ERROR 1064

```sql
SELECT
    c.customer_state,
    COUNT(*) AS total_order_count,
    COUNT(
        CASE
            WHEN o.order_status = 'delivered' THEN 1
        END
    ) AS delivered_count,
    COUNT(
        CASE
            WHEN o.order_status = 'canceled' THEN 1
        END
    ) AS canceled_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING total_order_count >= 1000
ORDER BY
    total_order_count DESC,
    customer_state ASC;
```

No result table is reproduced here. See the Korean source for the original execution notes.

## Exercise 4

**Question.** Across all available periods, count repeat customers per state, keeping at least twenty.

**Learning point.** The inner query counts orders per state/customer pair; the outer conditional sum counts pairs with at least two orders.

### Final query recorded in the journal

```sql
SELECT
    customer_state,
    SUM(
        CASE
            WHEN order_count >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customer_count
FROM (
    SELECT
        c.customer_state,
        c.customer_unique_id,
        COUNT(*) AS order_count
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_state,
        c.customer_unique_id
) AS customer_orders
GROUP BY customer_state
HAVING repeat_customer_count >= 20
ORDER BY
    repeat_customer_count DESC,
    customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | repeat_customer_count |
| --- | --- |
| SP | 1296 |
| RJ | 421 |
| MG | 338 |
| RS | 167 |
| PR | 145 |
| SC | 95 |
| BA | 93 |
| GO | 64 |
| DF | 62 |
| ES | 57 |
| PE | 33 |
| MT | 29 |
| PA | 24 |
| CE | 22 |

## Exercise 5

**Question.** Calculate 2018 repeat-customer percentages by state, keeping at least one thousand customers.

**Learning point.** Apply the year filter inside the customer-level query, then aggregate per state. Keep the denominator and the observation period explicit.

### Final query recorded in the journal

```sql
SELECT
    customer_state,
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN order_count >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        SUM(
            CASE
                WHEN order_count >= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS repeat_rate

FROM (

    SELECT
        c.customer_state,
        c.customer_unique_id,
        COUNT(*) AS order_count

    FROM orders o

    JOIN customers c
        ON c.customer_id = o.customer_id

    WHERE YEAR(o.order_purchase_timestamp) = 2018

    GROUP BY
        c.customer_state,
        c.customer_unique_id

) AS customer_order

GROUP BY customer_state

HAVING total_customers >= 1000

ORDER BY
    repeat_rate DESC,
    customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | total_customers | repeat_customers | repeat_rate |
| --- | --- | --- | --- |
| DF | 1182 | 30 | 2.54 |
| RJ | 6400 | 158 | 2.47 |
| GO | 1030 | 25 | 2.43 |
| SP | 23289 | 537 | 2.31 |
| BA | 1741 | 39 | 2.24 |
| RS | 2715 | 59 | 2.17 |
| MG | 6042 | 126 | 2.09 |
| PR | 2698 | 55 | 2.04 |
| ES | 1039 | 21 | 2.02 |
| SC | 1868 | 37 | 1.98 |

