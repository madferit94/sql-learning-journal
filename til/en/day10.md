# Day 10 — Monthly metrics and repeat-customer rates

[한국어 원기록](../ko/day10.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Count delivered orders purchased in 2017 by calendar month, ascending.

**Learning point.** YEAR chooses the year; DATE_FORMAT creates the YYYY-MM grouping label. Do not compare MONTH with 2017.

### Final query recorded in the journal

```sql
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS delivered_order_count
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2017
  AND order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month ASC;
```

### Recorded output (source excerpt)

| order_month | delivered_order_count |
| --- | --- |
| 2017-01 | 750 |
| 2017-02 | 1653 |
| 2017-03 | 2546 |
| 2017-04 | 2303 |
| 2017-05 | 3546 |
| 2017-06 | 3135 |
| 2017-07 | 3872 |
| 2017-08 | 4193 |
| 2017-09 | 4150 |
| 2017-10 | 4478 |
| 2017-11 | 7289 |
| 2017-12 | 5513 |

## Exercise 2

**Question.** Count distinct customers purchasing in 2018 by state, keeping at least five hundred.

**Learning point.** COUNT(DISTINCT customer_unique_id) differs from the number of order-linked customer records.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    c.customer_state,
    COUNT(*) AS customer_count
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
WHERE YEAR(order_purchase_timestamp) = 2018
GROUP BY customer_unique_id
HAVING customer_count >= 500
ORDER BY customer_count DESC, customer_count ASC;
```

### Final query recorded in the journal

```sql
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING customer_count >= 500
ORDER BY customer_count DESC,
         c.customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | customer_count |
| --- | --- |
| SP | 23289 |
| RJ | 6400 |
| MG | 6042 |
| RS | 2715 |
| PR | 2698 |
| SC | 1868 |
| BA | 1741 |
| DF | 1182 |
| ES | 1039 |
| GO | 1030 |
| PE | 862 |
| CE | 661 |

## Exercise 3

**Question.** Count 2018 orders by state and status for delivered and canceled orders, keeping combinations with at least fifty.

**Learning point.** Use IN for the two statuses and group by both fields. The earlier nested query introduced unnecessary alias-scope problems.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    c.customer_state,
    o.order_status
FROM (
    SELECT
        order_status,
        order_purchase_timestamp
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    WHERE YEAR(order_purchase_timestamp) = 2018
) AS order_count
GROUP BY order_status
HAVING order_count >= 50
ORDER BY customer_state ASC,
         order_count DESC;
```

### Final query recorded in the journal

```sql
SELECT
    c.customer_state,
    o.order_status,
    COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
  AND o.order_status IN ('delivered', 'canceled')
GROUP BY
    c.customer_state,
    o.order_status
HAVING order_count >= 50
ORDER BY
    c.customer_state ASC,
    order_count DESC;
```

### Recorded output (source excerpt)

| customer_state | order_status | order_count |
| --- | --- | --- |
| AL | delivered | 198 |
| AM | delivered | 72 |
| BA | delivered | 1726 |
| CE | delivered | 633 |
| DF | delivered | 1193 |
| ES | delivered | 1047 |
| GO | delivered | 1033 |
| MA | delivered | 346 |
| MG | delivered | 6079 |
| MS | delivered | 411 |
| MT | delivered | 476 |
| PA | delivered | 453 |
| PB | delivered | 269 |
| PE | delivered | 852 |
| PI | delivered | 258 |
| PR | delivered | 2711 |
| RJ | delivered | 6342 |
| RN | delivered | 241 |
| RO | delivered | 109 |
| RS | delivered | 2737 |
| SC | delivered | 1884 |
| SE | delivered | 146 |
| SP | delivered | 23335 |
| SP | canceled | 188 |
| TO | delivered | 144 |

## Exercise 4

**Question.** Across all available periods, list customers with at least three orders and their first and last purchase times.

**Learning point.** Group by customer_unique_id. The source reports 252 rows and shows only part of that output; do not treat the displayed excerpt as the full result.

### Final query recorded in the journal

```sql
SELECT
    c.customer_unique_id,
    COUNT(*) AS order_count,
    MIN(o.order_purchase_timestamp) AS first_order_date,
    MAX(o.order_purchase_timestamp) AS last_order_date
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING order_count >= 3
ORDER BY
    order_count DESC,
    c.customer_unique_id ASC;
```

### Recorded output (source excerpt)

| customer_unique_id | order_count | first_order_date | last_order_date |
| --- | --- | --- | --- |
| 8d50f5eadf50201ccdcedfb9e2ac8455 | 17 | 2017-05-15 23:30:03 | 2018-08-20 19:14:26 |
| 3e43e6105506432c953e165fb2acf44c | 9 | 2017-09-18 18:53:15 | 2018-02-27 18:36:39 |
| 1b6c7548a2a1f9037c1fd3ddfed95f33 | 7 |  |  |
| 6469f99c1f9dfae7733b25662e7f1782 | 7 |  |  |
| ca77025e7201e3b30c44b472ff346268 | 7 |  |  |
| ... |  |  |  |

## Exercise 5

**Question.** Calculate each state's repeat-customer percentage across all available periods, keeping at least five hundred customers and rounding to two decimals.

**Learning point.** First count orders per state/customer pair, then count all and repeat pairs per state. This is a repeat-customer share within the observed period, not a cohort retention rate.

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

    GROUP BY
        c.customer_state,
        c.customer_unique_id

) AS customer_orders

GROUP BY customer_state

HAVING COUNT(*) >= 500

ORDER BY
    repeat_rate DESC,
    customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | total_customers | repeat_customers | repeat_rate |
| --- | --- | --- | --- |
| RJ | 12384 | 421 | 3.40 |
| MT | 876 | 29 | 3.31 |
| GO | 1952 | 64 | 3.28 |
| SP | 40302 | 1296 | 3.22 |
| RS | 5277 | 167 | 3.16 |
| MG | 11259 | 338 | 3.00 |
| DF | 2075 | 62 | 2.99 |
| PR | 4882 | 145 | 2.97 |
| ES | 1964 | 57 | 2.90 |
| BA | 3277 | 93 | 2.84 |
| SC | 3534 | 95 | 2.69 |
| MS | 694 | 18 | 2.59 |
| PA | 949 | 24 | 2.53 |
| PB | 519 | 13 | 2.50 |
| MA | 726 | 17 | 2.34 |
| PE | 1609 | 33 | 2.05 |
| CE | 1313 | 22 | 1.68 |

