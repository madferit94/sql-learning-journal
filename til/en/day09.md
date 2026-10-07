# Day 09 — Olist joins and two-stage aggregation

[한국어 원기록](../ko/day09.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Count 2018 purchases by state, ordered by count descending then state ascending.

**Learning point.** Compare YEAR(timestamp) with 2018; a full timestamp is not equal to the integer year. An aggregate alias is not a column of table alias o.

### Earlier attempt (historical; may be invalid)

```sql
SELECT c.customer_state,
       COUNT(*) o.order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_purchase_timestamp = 2018
GROUP BY c.customer_state
ORDER BY o.order_count DESC, c.customer_state ASC;
```

### Final query recorded in the journal

```sql
SELECT c.customer_state,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
ORDER BY order_count DESC, c.customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | order_count |
| --- | --- |
| SP | 23871 |
| RJ | 6571 |
| MG | 6181 |
| RS | 2780 |
| PR | 2755 |
| SC | 1906 |
| BA | 1784 |
| DF | 1213 |
| ES | 1061 |
| GO | 1056 |

## Exercise 2

**Question.** Across all available periods, find customers with at least two orders, ordered by count descending then unique identifier ascending.

**Learning point.** Join using customer_id but group using customer_unique_id to count orders per customer.

### Earlier attempt (historical; may be invalid)

```sql
SELECT c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_unique_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC, customer_unique_id ASC;
```

### Final query recorded in the journal

```sql
SELECT c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC, customer_unique_id ASC;
```

### Recorded output (source excerpt)

| customer_unique_id | order_count |
| --- | --- |
| 8d50f5eadf50201ccdcedfb9e2ac8455 | 17 |
| 3e43e6105506432c953e165fb2acf44c | 9 |
| 1b6c7548a2a1f9037c1fd3ddfed95f33 | 7 |
| 6469f99c1f9dfae7733b25662e7f1782 | 7 |
| ca77025e7201e3b30c44b472ff346268 | 7 |

## Exercise 3

**Question.** Count delivered orders purchased in 2018 by state, keeping at least five hundred.

**Learning point.** The date condition refers to purchase time, independently of delivery status.

### Final query recorded in the journal

```sql
SELECT c.customer_state,
       COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND YEAR(order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING COUNT(*) >= 500
ORDER BY delivered_order_count DESC, customer_state ASC;
```

### Recorded output (source excerpt)

| customer_state | delivered_order_count |
| --- | --- |
| SP | 23335 |
| RJ | 6342 |
| MG | 6079 |
| RS | 2737 |
| PR | 2711 |
| SC | 1884 |
| BA | 1726 |
| DF | 1193 |
| ES | 1047 |
| GO | 1033 |
| PE | 852 |
| CE | 633 |

## Exercise 4

**Question.** Count delivered orders purchased in 2018 by state and city, keeping at least three hundred.

**Learning point.** Use purchase timestamp rather than delivery timestamp. Group by both geographic fields.

### Earlier attempt (historical; may be invalid)

```sql
SELECT c.customer_state,
       c.customer_city,
       COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE YEAR(order_delivered_customer_date) = 2018
GROUP BY customer_state, customer_city
HAVING delivered_order_count >= 300
ORDER BY delivered_order_count DESC,
         customer_state ASC,
         customer_city ASC;
```

### Final query recorded in the journal

```sql
SELECT c.customer_state,
       c.customer_city,
       COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE YEAR(order_purchase_timestamp) = 2018
  AND o.order_status = 'delivered'
GROUP BY customer_state, customer_city
HAVING delivered_order_count >= 300
ORDER BY delivered_order_count DESC,
         customer_state ASC,
         customer_city ASC;
```

### Recorded output (source excerpt)

| customer_state | customer_city | delivered_order_count |
| --- | --- | --- |
| SP | sao paulo | 8891 |
| RJ | rio de janeiro | 3376 |
| MG | belo horizonte | 1527 |
| DF | brasilia | 1193 |
| PR | curitiba | 851 |
| SP | campinas | 801 |
| SP | guarulhos | 673 |
| RS | porto alegre | 665 |
| BA | salvador | 649 |
| SP | sao bernardo do campo | 526 |

## Exercise 5

**Question.** Count repeat customers by state across all available periods.

**Learning point.** First count orders per state/customer pair and keep at least two; then count qualifying pairs per state. Do not sum identifiers or join customer_id to order_id.

### Earlier attempt (historical; may be invalid)

```sql
SELECT c.customer_state,
       SUM(c.customer_unique_id) AS repeat_customer_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE c.customer_unique_id >= 2
GROUP BY customer_state
ORDER BY repeat_customer_count DESC, customer_state ASC;
```

### Final query recorded in the journal

```sql
SELECT customer_state,
       COUNT(*) AS repeat_customer_count
FROM (
    SELECT c.customer_state,
           c.customer_unique_id,
           COUNT(*) AS order_count
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_state,
             c.customer_unique_id
    HAVING COUNT(*) >= 2
) AS repeat_customers
GROUP BY customer_state
ORDER BY repeat_customer_count DESC,
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
| MS | 18 |
| MA | 17 |
| PB | 13 |
| AL | 12 |
| PI | 11 |
| RN | 11 |
| RO | 10 |
| SE | 8 |
| TO | 7 |
| AC | 4 |
| AM | 3 |
| AP | 1 |
| RR | 1 |

