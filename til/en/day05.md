# Day 05 — Customer identifiers and joins

[한국어 원기록](../ko/day05.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Check whether customer_id occurs more than once in customers.

**Learning point.** Group by the identifier and use HAVING COUNT(*) >= 2. An empty result is a valid duplicate check outcome.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_id, COUNT(*) customer_count
FROM customers
GROUP BY customer_id
HAVING customer_count >= 2
ORDER BY customer_id DESC;
```

### Final query recorded in the journal

```sql
SELECT customer_id,
       COUNT(*) AS customer_count
FROM customers
GROUP BY customer_id
HAVING customer_count >= 2
ORDER BY customer_count DESC;
```

No result table is reproduced here. See the Korean source for the original execution notes.

## Exercise 2

**Question.** Find the ten most frequent customer_unique_id values with at least two customer records.

**Learning point.** Filter on the count rather than comparing an identifier to 2. Distinguish the order-linked customer_id from the person-level customer_unique_id.

### Earlier attempt (historical; may be invalid)

```sql
SELECT customer_unique_id, COUNT(*) customer_count
FROM customers
HAVING customer_unique_id > 1
ORDER BY customer_unique_id;
```

### Final query recorded in the journal

```sql
SELECT customer_unique_id,
       COUNT(*) AS customer_count
FROM customers
GROUP BY customer_unique_id
HAVING customer_count >= 2
ORDER BY customer_count DESC
LIMIT 10;
```

### Recorded output (source excerpt)

| `customer_unique_id` | `customer_count` |
| --- | --- |
| 8d50f5eadf50201ccdcedfb9e2ac8455 | 17 |
| 3e43e6105506432c953e165fb2acf44c | 9 |
| ca77025e7201e3b30c44b472ff346268 | 7 |
| 6469f99c1f9dfae7733b25662e7f1782 | 7 |
| 1b6c7548a2a1f9037c1fd3ddfed95f33 | 7 |
| f0e310a6839dce9de1638e0fe5ab282a | 6 |
| de34b16117594161a6a89c50b289d35a | 6 |
| dc813062e0fc23409cd255f7f53c7074 | 6 |
| 63cfc61cee11cbe306bff5857d00bfe4 | 6 |
| 47c1a3033b8b77b3ab6e109eb4d5fdf3 | 6 |

## Exercise 3

**Question.** Find the ten states with the most delivered orders.

**Learning point.** Join orders and customers on customer_id, then group by customer_state.

### Final query recorded in the journal

```sql
SELECT customer_state, COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY order_count DESC
LIMIT 10;
```

### Recorded output (source excerpt)

| `customer_state` | `order_count` |
| --- | --- |
| SP | 40501 |
| RJ | 12350 |
| MG | 11354 |
| RS | 5345 |
| PR | 4923 |
| SC | 3546 |
| BA | 3256 |
| DF | 2080 |
| ES | 1995 |
| GO | 1957 |

## Exercise 4

**Question.** Count delivered orders by purchase year and state; sort year ascending and count descending, returning twenty rows.

**Learning point.** The output grain is year plus state. A global LIMIT 20 does not mean twenty rows per year.

### Earlier attempt (historical; may be invalid)

```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       customer_state,
       COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY order_year DESC
LIMIT 20;
```

### Final query recorded in the journal

```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       customer_state,
       COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY order_year, customer_state
ORDER BY order_year, order_count DESC
LIMIT 20;
```

### Recorded output (source excerpt)

| `order_year` | `customer_state` | `order_count` |
| --- | --- | --- |
| 2016 | SP | 95 |
| 2016 | RJ | 40 |
| 2016 | MG | 35 |
| 2016 | PR | 20 |
| 2016 | RS | 17 |
| 2016 | SC | 9 |
| 2016 | GO | 7 |
| 2016 | PE | 6 |
| 2016 | DF | 6 |
| 2016 | CE | 6 |
| 2016 | RN | 4 |
| 2016 | PA | 4 |
| 2016 | MA | 4 |
| 2016 | SE | 3 |
| 2016 | ES | 3 |
| 2016 | BA | 3 |
| 2016 | RR | 1 |
| 2016 | PI | 1 |
| 2016 | PB | 1 |
| 2016 | MT | 1 |

## Exercise 5

**Question.** Compare delivered-order counts before and after joining customers.

**Learning point.** Equal totals are a useful check, but they do not alone prove join integrity. Also inspect unmatched keys and key uniqueness.

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS joined_delivered_count
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered';
```

### Recorded output (source excerpt)

| `joined_delivered_count` |
| --- |
| 96478 |

