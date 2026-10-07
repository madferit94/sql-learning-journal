# Day 04 — Olist order aggregation

[한국어 원기록](../ko/day04.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Show the ten earliest purchases among delivered orders.

**Learning point.** Sort by order_purchase_timestamp, not by the status that is already fixed by WHERE.

### Earlier attempt (historical; may be invalid)

```sql
SELECT order_id, order_status, order_purchase_timestamp
FROM orders
WHERE order_status = 'delivered'
ORDER BY order_id
LIMIT 10;
```

### Final query recorded in the journal

```sql
SELECT order_id, order_status, order_purchase_timestamp
FROM orders
WHERE order_status = 'delivered'
ORDER BY order_purchase_timestamp
LIMIT 10;
```

### Recorded output (source excerpt)

| `order_id` | `order_status` | `order_purchase_timestamp` |
| --- | --- | --- |
| bfbd0f9b... | delivered | 2016-09-15 12:16:38 |
| 3b697a20... | delivered | 2016-10-03 09:44:50 |
| be5bc2f0... | delivered | 2016-10-03 16:56:50 |
| a41c8759... | delivered | 2016-10-03 21:13:36 |
| d207cc27... | delivered | 2016-10-03 22:06:03 |
| cd3b8574... | delivered | 2016-10-03 22:31:31 |
| ae8a60e4... | delivered | 2016-10-03 22:44:10 |
| ef1b29b5... | delivered | 2016-10-03 22:51:30 |
| 0a0837a5... | delivered | 2016-10-04 09:06:10 |
| 1ff217aa... | delivered | 2016-10-04 09:16:33 |

## Exercise 2

**Question.** Count orders by status, descending.

**Learning point.** Selecting an ungrouped order_id caused a grouping error. The source records 99,441 total orders across statuses.

### Earlier attempt (historical; may be invalid)

```sql
SELECT order_id, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC
LIMIT 10;
```

### Final query recorded in the journal

```sql
SELECT order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;
```

### Recorded output (source excerpt)

| `order_status` | `order_count` |
| --- | --- |
| delivered | 96478 |
| shipped | 1107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

## Exercise 3

**Question.** Count delivered orders by purchase year, ascending.

**Learning point.** Group by YEAR(order_purchase_timestamp), not the full timestamp.

### Earlier attempt (historical; may be invalid)

```sql
SELECT order_status,
       YEAR(order_purchase_timestamp),
       COUNT(*) AS order_count
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_purchase_timestamp
ORDER BY order_count DESC
LIMIT 10;
```

### Final query recorded in the journal

```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year;
```

### Recorded output (source excerpt)

| `order_year` | `order_count` |
| --- | --- |
| 2016 | 267 |
| 2017 | 43428 |
| 2018 | 52783 |

## Exercise 4

**Question.** Count all orders by purchase year, keeping years with at least 1,000 orders and sorting by count descending.

**Learning point.** Use HAVING for a condition on the annual count.

### Earlier attempt (historical; may be invalid)

```sql
SELECT order_status,
       YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_status
HAVING order_count >= '1000'
ORDER BY order_count;
```

### Final query recorded in the journal

```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_year
HAVING order_count >= 1000
ORDER BY order_count DESC;
```

### Recorded output (source excerpt)

| `order_year` | `order_count` |
| --- | --- |
| 2018 | 54011 |
| 2017 | 45101 |

## Exercise 5

**Question.** For delivered orders, show each purchase year's count, first purchase and last purchase.

**Learning point.** MIN and MAX expose partial coverage. The source notes partial 2016 and 2018 periods, so annual totals alone do not establish growth.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS order_count,
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year DESC;
```

### Final query recorded in the journal

```sql
SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS order_count,
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year;
```

### Recorded output (source excerpt)

| `order_year` | `order_count` | `first_order` | `last_order` |
| --- | --- | --- | --- |
| 2016 | 267 | 2016-09-15 12:16:38 | 2016-12-23 23:16:47 |
| 2017 | 43428 | 2017-01-05 11:56:06 | 2017-12-31 23:29:31 |
| 2018 | 52783 | 2018-01-01 02:48:41 | 2018-08-29 15:00:37 |

