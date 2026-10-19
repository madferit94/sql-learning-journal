# Day 17 — Online Retail monthly aggregation, date filters and subqueries

[한국어](../ko/day17.md) · [Index](../../README.md)

Edited from the Notion journal in the same format as the earlier English editions. SQL and outputs are historical user-run evidence, not rerun for this publication. These are custom exercises in a coding-platform format, not official Programmers or LeetCode questions.

## Tables and row grain

`sales_items` exposes original item rows with positive quantity and price and no C-prefixed invoice. One row is an invoice item, not a whole invoice or a unit. Duplicates and unknown customer IDs remain. There are 530,104 rows spanning December 2010 to December 2011; price is GBP.

| Column | Type | Meaning |
| --- | --- | --- |
| invoice_header_id | INT | Join key to the derived header record |
| invoice_date | DATETIME | Purchase timestamp |
| customer_id | VARCHAR(20) | Customer ID; may be NULL |
| quantity | INT | Units on the item row |
| unit_price | DECIMAL(16,6) | Price per unit in GBP |

`invoice_headers` contains a unique combination of invoice number, timestamp, customer and country, identified by invoice_header_id. It has invoice_date, customer_id (nullable) and country. One header may link to several items. Use the ID, not invoice_no alone; header count is not a distinct-invoice count. See [data notes](../../docs/data.en.md) for provenance and caveats.

`DATE_FORMAT(invoice_date, '%Y-%m')` produces strings such as `2011-03`. Use it to distinguish years when grouping months; compare original DATETIME values directly for period filters.

## Exercise 1 — Monthly quantities and sales amounts

**Question.** Using sales_items across all periods, return purchase_month as YYYY-MM, total_quantity as the sum of quantity, and total_sales_amount as the sum of quantity times unit_price rounded to two decimals. Keep years separate, include unknown-customer rows, show only observed months, and sort purchase_month ascending. No minimum count, quantity or value filter applies.

**Learning point.** The first attempt mixed in a previous high-value count, misspelled FROM, omitted quotes around the date format, used AS in GROUP BY and sorted by amount. The final query groups and sorts using the SELECT alias.

**Authorship and evidence.** Learner wrote the attempt and revised it after hints about SUM, grouping, sorting and syntax. User execution returned 13 rows in 0.73 seconds.

### Earlier attempt (historical; may be invalid)

```sql
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS purchase_month,
    COUNT(CASE WHEN quantity * unit_price >= 1000 THEN 1 END) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FORM sales_items
GROUP BY DATE_FORMAT(invoice_date, %Y-%m) AS purchase_month
ORDER BY total_sales_amount DESC;
```

### Final query recorded in the journal

```sql
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS purchase_month,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FROM sales_items
GROUP BY purchase_month
ORDER BY purchase_month ASC;
```

### Recorded output (source excerpt)

| purchase_month | total_quantity | total_sales_amount |
| --- | --- | --- |
| 2010-12 | 359239 | 823746.14 |
| 2011-01 | 387785 | 691364.56 |
| 2011-02 | 283555 | 523631.89 |
| 2011-03 | 377526 | 717639.36 |
| 2011-04 | 308815 | 537808.62 |
| 2011-05 | 395738 | 770536.02 |
| 2011-06 | 389213 | 761739.90 |
| 2011-07 | 401759 | 719221.19 |
| 2011-08 | 421770 | 759138.38 |
| 2011-09 | 570820 | 1058590.17 |
| 2011-10 | 623401 | 1154979.30 |
| 2011-11 | 754507 | 1509496.33 |
| 2011-12 | 314248 | 638792.68 |

## Exercise 2 — Monthly high-value item percentage

**Question.** For each observed YYYY-MM across all periods, return item_count (line-item rows), high_amount_count (rows with quantity times unit_price at least GBP 100), and high_amount_rate as 100 times high_amount_count divided by item_count, rounded to two decimals. Include unknown customers and months with zero high-value items; sort month ascending. There is no minimum item count.

**Learning point.** A row with many units is still one item row. Preserve all monthly item rows in the denominator and apply the value condition only to the numerator.

**Authorship and evidence.** First submission correct without query correction. User execution: 13 rows in 0.66 seconds. The actual output had no zero-high-value month, although the query would retain one.

### Final query recorded in the journal

```sql
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS purchase_month,
    COUNT(*) AS item_count,
    COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END) AS high_amount_count,
    ROUND(
        COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END)
        / COUNT(*) * 100, 2
    ) AS high_amount_rate
FROM sales_items
GROUP BY purchase_month
ORDER BY purchase_month ASC;
```

### Recorded output (source excerpt)

| purchase_month | item_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| 2010-12 | 41480 | 1056 | 2.55 |
| 2011-01 | 34306 | 794 | 2.31 |
| 2011-02 | 27105 | 764 | 2.82 |
| 2011-03 | 35803 | 1083 | 3.02 |
| 2011-04 | 29096 | 663 | 2.28 |
| 2011-05 | 36164 | 1049 | 2.90 |
| 2011-06 | 35977 | 991 | 2.75 |
| 2011-07 | 38645 | 932 | 2.41 |
| 2011-08 | 34483 | 1058 | 3.07 |
| 2011-09 | 49261 | 1340 | 2.72 |
| 2011-10 | 59304 | 1395 | 2.35 |
| 2011-11 | 83369 | 1909 | 2.29 |
| 2011-12 | 25111 | 541 | 2.15 |

## Exercise 3 — Country sales in 2011

**Question.** Join invoice_headers and sales_items using invoice_header_id. Use header country/date and item quantity/price. Keep purchases from 2011-01-01 inclusive to 2012-01-01 exclusive, including unknown customers. Return country, item_count, total_quantity and total_sales_amount rounded to two decimals for countries with at least 100 item rows. Sort rounded amount descending then country ascending.

**Learning point.** Use WHERE for individual purchase dates and HAVING for the grouped item count. Quote date literals. Backticks around a whole multiplication expression would mean a column name, not arithmetic.

**Authorship and evidence.** Join and aggregate structure written by learner; AI helped with date-filter location, literals, backticks and a space inside the sort alias. Final user output: 29 rows in 1.21 seconds.

### Earlier attempt (historical; may be invalid)

```sql
SELECT h.country, COUNT(*) AS item_count,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(`quantity * unit_price`), 2) AS total_sales_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
GROUP BY h.country
HAVING item_count >= 100
   AND DATE_FORMAT(h.invoice_date, '%Y-%m-%d') >= 2011-01-01
   AND DATE_FORMAT(h.invoice_date, '%Y-%m-%d') < 2012-01-01
ORDER BY total_sales_amount DESC, h.country ASC;
```

### Final query recorded in the journal

```sql
SELECT h.country, COUNT(*) AS item_count,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.quantity * s.unit_price), 2) AS total_sales_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
WHERE h.invoice_date >= '2011-01-01'
  AND h.invoice_date < '2012-01-01'
GROUP BY h.country
HAVING item_count >= 100
ORDER BY total_sales_amount DESC, h.country ASC;
```

### Recorded output (source excerpt)

| country | item_count | total_quantity | total_sales_amount |
| --- | --- | --- | --- |
| United Kingdom | 445899 | 4348230 | 8276953.10 |
| Netherlands | 2287 | 193550 | 276661.86 |
| EIRE | 7517 | 141403 | 273420.70 |
| Germany | 8528 | 112384 | 213626.00 |
| France | 7973 | 107114 | 200098.80 |
| Australia | 1150 | 83434 | 137488.46 |
| Spain | 2409 | 27073 | 59733.38 |
| Switzerland | 1917 | 29915 | 55784.98 |
| Belgium | 1936 | 21482 | 39386.43 |
| Sweden | 425 | 32129 | 34544.03 |
| Norway | 924 | 15754 | 32378.32 |
| Portugal | 1385 | 15274 | 31307.13 |
| Japan | 256 | 21923 | 29711.30 |
| Finland | 668 | 9450 | 21653.28 |
| Singapore | 222 | 5241 | 21279.29 |
| Channel Islands | 731 | 9411 | 20086.91 |
| Denmark | 360 | 7781 | 17673.84 |
| Italy | 718 | 7817 | 16671.74 |
| Hong Kong | 284 | 4773 | 15691.80 |
| Cyprus | 531 | 5444 | 11999.56 |
| Austria | 390 | 4830 | 9921.48 |
| Israel | 295 | 4409 | 8135.26 |
| Poland | 322 | 3544 | 7086.49 |
| Greece | 145 | 1557 | 4760.52 |
| Unspecified | 446 | 3300 | 4749.79 |
| Canada | 151 | 2763 | 3666.38 |
| Iceland | 151 | 2139 | 3598.21 |
| USA | 179 | 2458 | 3580.39 |
| Malta | 112 | 970 | 2725.59 |

## Exercise 4 — Count customers purchasing in at least three months

**Question.** Using sales_items only, count known customers with purchases in at least three distinct calendar months of 2011. Restrict dates to 2011-01-01 inclusive and 2012-01-01 exclusive; exclude NULL customer IDs. Repeated purchases within one month count as one month. Months need not be consecutive and exactly three qualifies. Return one customer_count row, zero if none qualify.

**Learning point.** DATE_FORMAT converts timestamps to year-month values; DISTINCT removes repeated months; COUNT counts the remaining values. Calculating a month count alone does not filter customers: the grouped threshold must still be applied.

**Authorship and evidence.** Learner wrote the derived-table structure. AI supplied the distinct-month expression and hints for NULL exclusion and HAVING. Earlier runs without these filters returned 4220; final user run returned 1692 in 0.92 seconds. Independent explanation/rewrite after the hints was not established.

### Earlier attempt (historical; may be invalid)

```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT COUNT(*) AS customer
    FROM sales_items
    WHERE invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
) AS count;
```

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT COUNT(DISTINCT DATE_FORMAT(invoice_date, '%Y-%m')) AS purchase_month_count
    FROM sales_items
    WHERE customer_id IS NOT NULL
      AND invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
    HAVING purchase_month_count >= 3
) AS count;
```

### Recorded output (source excerpt)

| customer_count |
| --- |
| 1692 |

## Exercise 5 — Mean annual total for qualifying customers

**Question.** For known customers who purchased in at least three distinct months of 2011, calculate each customer's total 2011 purchase amount, then the mean of those customer totals. Use all 2011 item amounts for each qualifying customer, even if purchases repeat within a month. Give each customer equal weight regardless of month/item count. Do not round customer totals; round only the final mean to two decimals as avg_customer_total. Use sales_items only; return one row.

**Learning point.** The three-month rule selects customers; it is not the denominator of a monthly average. The outer AVG reads one annual total per selected customer, not individual item amounts.

**Authorship and evidence.** Learner constructed the month count, date/NULL filters, total and outer AVG. AI helped move rounding to the final result. Initial output was 3915.728800; both later display values were 3915.73, but only the final query removed intermediate rounding. Final execution: 0.97 seconds. The learner then said the meaning was unclear; an explanation followed, with no subsequent independent restatement confirmed.

### Earlier attempt (historical; may be invalid)

```sql
SELECT AVG(total_amount) AS avg_customer_total
FROM (
    SELECT COUNT(DISTINCT DATE_FORMAT(invoice_date, '%Y-%m')) AS purchase_month_count,
        SUM(quantity) AS total_quantity,
        ROUND(SUM(quantity * unit_price), 2) AS total_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
      AND invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
    HAVING purchase_month_count >= 3
) AS customer;
```

### Final query recorded in the journal

```sql
SELECT ROUND(AVG(total_amount), 2) AS avg_customer_total
FROM (
    SELECT COUNT(DISTINCT DATE_FORMAT(invoice_date, '%Y-%m')) AS purchase_month_count,
        SUM(quantity * unit_price) AS total_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
      AND invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
    HAVING purchase_month_count >= 3
) AS customer;
```

### Recorded output (source excerpt)

| avg_customer_total |
| --- |
| 3915.73 |

## Understanding the final result

The three-month rule selects 1,692 customers. Each selected customer contributes one total for all their 2011 item purchases; averaging those totals gives GBP 3,915.73 per selected customer. This is neither per order nor per month. A customer with only two observed purchasing months is excluded even if their amount is large. Execution success and independent understanding are recorded separately: the last question still needs an answer-free rewrite and a learner explanation.
