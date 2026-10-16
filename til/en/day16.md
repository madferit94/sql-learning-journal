# Day 16 — Online Retail quantities, customer joins and totals

[한국어](../ko/day16.md) · [Index](../../README.md)

Study date: 2026-10-15 to 2026-10-16. Edited translation of every exercise, with historical SQL and source output excerpts; not rerun for publication.

Schema and row-grain details: [data notes](../../docs/data.en.md). Questions are custom practice exercises in a coding-platform format, not official Programmers or LeetCode problems.

## Exercise 1 — Country quantities and sales amounts

**Question.** Using sales_items, return countries with at least 1,000 units sold, their quantity sum and sum of quantity times unit_price rounded to two decimals. Include unknown-customer rows; sort amount descending and country ascending.

**Learning point.** Item rows, units and monetary amounts are different measures.

**Authorship and evidence.** First submission correct. User executed P1 on October 15: 28 rows.

### Final query recorded in the journal

```sql
SELECT country, SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FROM sales_items
GROUP BY country
HAVING total_quantity >= 1000
ORDER BY total_sales_amount DESC, country ASC;
```

### Recorded output (source excerpt)

| country | total_quantity | total_sales_amount |
| --- | --- | --- |
| United Kingdom | 4662390 | 9025222.08 |
| Netherlands | 200361 | 285446.34 |
| EIRE | 147173 | 283453.96 |
| Germany | 119261 | 228867.14 |
| France | 112103 | 209715.11 |
| Australia | 83901 | 138521.31 |
| Spain | 27940 | 61577.11 |
| Switzerland | 30629 | 57089.90 |
| Belgium | 23237 | 41196.34 |
| Sweden | 36083 | 38378.33 |
| Japan | 26016 | 37416.37 |
| Norway | 19336 | 36165.44 |
| Portugal | 16258 | 33747.10 |
| Finland | 10704 | 22546.08 |
| Singapore | 5241 | 21279.29 |
| Channel Islands | 9491 | 20450.44 |
| Denmark | 8235 | 18955.34 |
| Italy | 8112 | 17483.24 |
| Hong Kong | 4773 | 15691.80 |
| Cyprus | 6361 | 13590.38 |
| Austria | 4881 | 10198.68 |
| Israel | 4409 | 8135.26 |
| Poland | 3684 | 7334.65 |
| Greece | 1557 | 4760.52 |
| Unspecified | 3300 | 4749.79 |
| Iceland | 2458 | 4310.00 |
| Canada | 2763 | 3666.38 |
| USA | 2458 | 3580.39 |

## Exercise 2 — High-value item percentage

**Question.** For countries with at least 100 item rows, count rows worth at least GBP 100 and their percentage, rounded to two decimals. Include zero high-value counts; sort percentage descending then country ascending.

**Learning point.** High value refers to quantity times unit price, not unit price alone. Both conditional counts must use the same predicate.

**Authorship and evidence.** AI guidance and cleaned code supplied. Markdown artifacts were clarified as paste errors. User ran P2 on October 16: 29 rows, including USA and Unspecified at 0%.

### Earlier attempt (historical; may be invalid)

```sql
SELECT, country, COUNT(*) AS item_count,
    COUNT(CASE WHEN unit_price >= 100 THEN 1 END) AS high_amount_count,
    ROUND(COUNT(CASE WHEN unit_price >= 100 THEN 1 END)
        / COUNT(*) * 100, 2) AS high_amount_rate
FROM sales_item
GROUP BY country
HAVING item_count >= 100
ORDER BY high_amount_rate DESC, country ASC;
```

### Final query recorded in the journal

```sql
SELECT country, COUNT(*) AS item_count,
    COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END) AS high_amount_count,
    ROUND(
        COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END)
        / COUNT(*) * 100, 2
    ) AS high_amount_rate
FROM sales_items
GROUP BY country
HAVING item_count >= 100
ORDER BY high_amount_rate DESC, country ASC;
```

### Recorded output (source excerpt)

| country | item_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| Netherlands | 2359 | 1132 | 47.99 |
| Japan | 321 | 126 | 39.25 |
| Australia | 1182 | 446 | 37.73 |
| Sweden | 451 | 136 | 30.16 |
| Denmark | 380 | 43 | 11.32 |
| Greece | 145 | 14 | 9.66 |
| Singapore | 222 | 16 | 7.21 |
| Finland | 685 | 43 | 6.28 |
| EIRE | 7890 | 469 | 5.94 |
| Hong Kong | 284 | 14 | 4.93 |
| Switzerland | 1966 | 95 | 4.83 |
| Israel | 295 | 14 | 4.75 |
| Norway | 1071 | 43 | 4.01 |
| Austria | 398 | 13 | 3.27 |
| Channel Islands | 748 | 22 | 2.94 |
| Spain | 2484 | 73 | 2.94 |
| Germany | 9040 | 246 | 2.72 |
| Cyprus | 614 | 14 | 2.28 |
| United Kingdom | 485123 | 10387 | 2.14 |
| France | 8407 | 165 | 1.96 |
| Malta | 112 | 2 | 1.79 |
| Iceland | 182 | 3 | 1.65 |
| Portugal | 1501 | 23 | 1.53 |
| Canada | 151 | 2 | 1.32 |
| Italy | 758 | 8 | 1.06 |
| Belgium | 2031 | 16 | 0.79 |
| Poland | 330 | 2 | 0.61 |
| USA | 179 | 0 | 0.00 |
| Unspecified | 446 | 0 | 0.00 |

## Exercise 3 — Customer quantities and purchases

**Question.** Join sales_items to invoice_headers by invoice_header_id. Exclude unknown customers. For customers with at least 100 units, show ID, item-row count, quantity sum and purchase total rounded to two decimals. Sort total descending then ID ascending.

**Learning point.** COUNT(quantity) counts rows, not units. Exclude NULL customers instead of treating their pooled records as one person.

**Authorship and evidence.** Join and amount formula written correctly; AI guided COUNT-to-SUM and NULL filtering. Only the shared 21-row excerpt is recorded; total output size and time were not supplied.

### Earlier attempt (historical; may be invalid)

```sql
SELECT h.customer_id, COUNT(*) AS item_count,
    COUNT(quantity) AS total_quantity,
    ROUND(SUM(s.quantity * s.unit_price), 2) AS total_purchase_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
GROUP BY h.customer_id
HAVING total_quantity >= 100
ORDER BY total_purchase_amount DESC, h.customer_id ASC;
```

### Final query recorded in the journal

```sql
SELECT h.customer_id, COUNT(*) AS item_count,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.quantity * s.unit_price), 2) AS total_purchase_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
WHERE h.customer_id IS NOT NULL
GROUP BY h.customer_id
HAVING total_quantity >= 100
ORDER BY total_purchase_amount DESC, h.customer_id ASC;
```

### Recorded output (source excerpt)

| customer_id | item_count | total_quantity | total_purchase_amount |
| --- | --- | --- | --- |
| 14646 | 2076 | 196915 | 280206.02 |
| 18102 | 431 | 64124 | 259657.30 |
| 17450 | 337 | 69993 | 194550.79 |
| 16446 | 3 | 80997 | 168472.50 |
| 14911 | 5675 | 80265 | 143825.06 |
| 12415 | 714 | 77374 | 124914.53 |
| 14156 | 1400 | 57885 | 117379.63 |
| 17511 | 963 | 64549 | 91062.38 |
| 16029 | 242 | 40208 | 81024.84 |
| 12346 | 1 | 74215 | 77183.60 |
| 16684 | 277 | 50255 | 66653.56 |
| 14096 | 5111 | 16352 | 65164.79 |
| 13694 | 568 | 63312 | 65039.62 |
| 15311 | 2379 | 38194 | 60767.90 |
| 13089 | 1818 | 31070 | 58825.83 |
| 17949 | 70 | 30546 | 58510.48 |
| 15769 | 130 | 29672 | 56252.72 |
| 15061 | 403 | 28920 | 54534.14 |
| 14298 | 1637 | 58343 | 51527.30 |
| 14088 | 589 | 12665 | 50491.81 |
| 15749 | 10 | 18028 | 44534.30 |

## Exercise 4 — Count customers with at least GBP 1,000

**Question.** Exclude NULL customer IDs and sum quantity times price per customer across all periods. Count customers whose unrounded total is at least GBP 1,000. Return one row, zero if none qualify.

**Learning point.** The inner grouping already creates one customer per row, even when customer_id is not selected.

**Authorship and evidence.** First submission correct with no query correction. User result: 1668.

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT SUM(quantity * unit_price) AS price
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING price >= 1000
) AS count;
```

### Recorded output (source excerpt)

| customer_count |
| --- |
| 1668 |

## Exercise 5 — Average qualifying customer total

**Question.** For known customers with cumulative purchases of at least GBP 1,000, average their customer-level totals with equal weight per customer. Do not round totals; round only the final mean to two decimals.

**Learning point.** Reuse the customer-level intermediate result from Exercise 4, then average the total column rather than counting rows.

**Authorship and evidence.** First submission correct with no query correction. User result: 4678.46. Two consecutive subquery exercises transferred the pattern to a new dataset.

### Final query recorded in the journal

```sql
SELECT ROUND(AVG(price), 2) AS avg_customer_total
FROM (
    SELECT SUM(quantity * unit_price) AS price
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING price >= 1000
) AS count;
```

### Recorded output (source excerpt)

| avg_customer_total |
| --- |
| 4678.46 |

