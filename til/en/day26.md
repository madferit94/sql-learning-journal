# Day 26 — Retail representatives, CTE alternatives and top-two re-aggregation

[한국어](../ko/day26.md) · [Index](../../README.md)

Five questions, eight retained query variants. Publication exercise indices 1–8 map to questions 1, 2-1, 2-2, 2-3, 3-1, 3-2, 4 and 5. Historical user results and later execution checks are distinct.

```bash
mysql -u root -p
```

```sql
USE retail_study;
```

## Exercise 1 — One representative customer per country

Original question/case: 1.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Use ROW_NUMBER to choose one customer per country by unrounded purchase amount DESC, customer_id ASC as a string. Round output only to two decimals. Return country, customer_id, item_count, total_purchase_amount; one representative per country. Final country ASC.

**Fictional example.** Fictional country A has C01/C02 tied at 1200; select C01.

### Initial attempt excerpt

```sql
ROW_NUMBER() OVER (PARTITION BY country ORDER BY purchase_amount DESC) AS total_purchase_amount
-- Outer query attempted WHERE rn = 1; the alias rn was not defined.
```

### Final query recorded in the journal

```sql
WITH purchase_amount AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
country_ranked AS (
    SELECT country, customer_id, item_count, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM purchase_amount
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM country_ranked
WHERE rn = 1
ORDER BY country ASC;
```

### Recorded output (source excerpt)

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Australia | 12415 | 714 | 124914.53 |
| Austria | 12360 | 129 | 2662.06 |
| Bahrain | 12355 | 13 | 459.40 |
| Belgium | 12362 | 266 | 5226.23 |
| Brazil | 12769 | 32 | 1143.60 |
| Canada | 17444 | 135 | 2940.04 |
| Channel Islands | 14936 | 364 | 8137.02 |
| Cyprus | 12359 | 248 | 6372.58 |
| Czech Republic | 12781 | 25 | 826.74 |
| Denmark | 12435 | 36 | 7829.89 |
| EIRE | 14911 | 5675 | 143825.06 |
| European Community | 15108 | 60 | 1300.25 |
| Finland | 12428 | 294 | 7956.46 |
| France | 12731 | 274 | 18895.91 |
| Germany | 12471 | 460 | 19824.05 |
| Greece | 14439 | 32 | 2661.24 |
| Iceland | 12347 | 182 | 4310.00 |
| Israel | 12688 | 171 | 4873.81 |
| Italy | 12594 | 118 | 3338.22 |
| Japan | 12753 | 197 | 21429.39 |
| Lebanon | 12764 | 45 | 1693.88 |
| Lithuania | 15332 | 35 | 1661.06 |
| Malta | 17828 | 67 | 1820.09 |
| Netherlands | 14646 | 2076 | 280206.02 |
| Norway | 12433 | 420 | 13375.87 |
| Poland | 12779 | 149 | 3981.36 |
| Portugal | 12757 | 371 | 7857.10 |
| RSA | 12446 | 57 | 1002.31 |
| Saudi Arabia | 12565 | 9 | 145.92 |

Partial user output; full row count/runtime not supplied.

### Correction and interpretation

The first attempt labeled ROW_NUMBER as total_purchase_amount and omitted the actual purchase amount from the second CTE output. rn is a chosen column alias, not a MySQL keyword. Pass the amount onward and add the customer-ID tie-breaker. Design aggregate→number→select dependencies before choosing a CTE count.

## Exercise 2 — Question 2 case 1: two CTEs, pre-ranking threshold

Original question/case: 2-1.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Choose each country’s maximum-amount representative by unrounded amount DESC, customer_id ASC, and require amount >= 10000 including the boundary. Round output only. Return country, customer_id, item_count, total_purchase_amount; one qualifying country representative. Final unrounded amount DESC, country ASC. This submitted form filters totals before numbering.

**Fictional example.** Fictional country representatives 15000/9000/10000 retain the first and third.

### Final query recorded in the journal

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
customer_country_purchase AS (
    SELECT country, customer_id, item_count, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM country_purchase
    WHERE purchase_amount >= 10000
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM customer_country_purchase
WHERE rn = 1
ORDER BY purchase_amount DESC, country ASC;
```

### Recorded output (source excerpt)

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Netherlands | 14646 | 2076 | 280206.02 |
| United Kingdom | 18102 | 431 | 259657.30 |
| EIRE | 14911 | 5675 | 143825.06 |
| Australia | 12415 | 714 | 124914.53 |
| Sweden | 17404 | 198 | 31906.82 |
| Japan | 12753 | 197 | 21429.39 |
| Singapore | 12744 | 222 | 21279.29 |
| Germany | 12471 | 460 | 19824.05 |
| France | 12731 | 274 | 18895.91 |
| Spain | 12540 | 478 | 13400.24 |
| Norway | 12433 | 420 | 13375.87 |
| Switzerland | 12409 | 109 | 11072.67 |

User terminal: 12 rows / 2.89 sec.

### Correction and interpretation

The second CTE WHERE applies before its window numbering. In this special maximum-value/lower-bound case, filtering low totals first is equivalent to selecting the maximum then checking the same bound. Unlike selecting by latest date then testing amount, it cannot replace a nonqualifying winner with an older transaction. Sort by unrounded amount, not the rounded display alias.

## Exercise 3 — Question 2 case 2: redundant inner and outer thresholds

Original question/case: 2-2.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Same Question 2 scope, threshold, tie-breaking, output and ordering. Submitted two-CTE case retains the >= 10000 condition both before numbering and after selecting rn=1. This duplication is redundant.

**Fictional example.** The same fictional example retains the same representatives with a redundant threshold.

### Final query recorded in the journal

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
customer_country_purchase AS (
    SELECT country, customer_id, item_count, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM country_purchase
    WHERE purchase_amount >= 10000
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM customer_country_purchase
WHERE rn = 1 AND purchase_amount >= 10000
ORDER BY purchase_amount DESC, country ASC;
```

### Recorded output (source excerpt)

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Netherlands | 14646 | 2076 | 280206.02 |
| United Kingdom | 18102 | 431 | 259657.30 |
| EIRE | 14911 | 5675 | 143825.06 |
| Australia | 12415 | 714 | 124914.53 |
| Sweden | 17404 | 198 | 31906.82 |
| Japan | 12753 | 197 | 21429.39 |
| Singapore | 12744 | 222 | 21279.29 |
| Germany | 12471 | 460 | 19824.05 |
| France | 12731 | 274 | 18895.91 |
| Spain | 12540 | 478 | 13400.24 |
| Norway | 12433 | 420 | 13375.87 |
| Switzerland | 12409 | 109 | 11072.67 |

User terminal: 12 rows / 0.84 sec.

### Correction and interpretation

The outer amount test repeats the inner filter and has no effect. Both queries are valid, but the second predicate is redundant. Single recorded runtimes 2.89 and 0.84 seconds do not establish a performance advantage.

## Exercise 4 — Question 2 case 3: one CTE with grouping and numbering

Original question/case: 2-3.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Same Question 2 scope, threshold, tie-breaking, output and ordering. Submitted one-CTE case combines GROUP BY, HAVING and ROW_NUMBER and uses SUM(...) directly in window ordering.

**Fictional example.** The same fictional example retains the same representatives with one CTE.

### Final query recorded in the journal

```sql
WITH ranked_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY SUM(quantity * unit_price) DESC, customer_id ASC
           ) AS rn
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
    HAVING SUM(quantity * unit_price) >= 10000
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM ranked_purchase
WHERE rn = 1
ORDER BY purchase_amount DESC, country ASC;
```

### Recorded output (source excerpt)

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Netherlands | 14646 | 2076 | 280206.02 |
| United Kingdom | 18102 | 431 | 259657.30 |
| EIRE | 14911 | 5675 | 143825.06 |
| Australia | 12415 | 714 | 124914.53 |
| Sweden | 17404 | 198 | 31906.82 |
| Japan | 12753 | 197 | 21429.39 |
| Singapore | 12744 | 222 | 21279.29 |
| Germany | 12471 | 460 | 19824.05 |
| France | 12731 | 274 | 18895.91 |
| Spain | 12540 | 478 | 13400.24 |
| Norway | 12433 | 420 | 13375.87 |
| Switzerland | 12409 | 109 | 11072.67 |

User terminal: 12 rows / 1.23 sec.

### Correction and interpretation

GROUP BY/SUM, then HAVING, then window numbering may share one CTE. Window ordering uses SUM(...) directly instead of a same-SELECT alias. Final sorting uses the unrounded amount. Two CTEs are not mandatory.

## Exercise 5 — Question 3 case 1: two CTEs, ranks within the top two

Original question/case: 3-1.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Use country-level RANK on unrounded purchase amount only; equal amounts tie and the next rank is skipped. Keep ranks <= 2 including all boundary ties; no 10000 threshold. Return country, country_rank, customer_id, item_count, total_purchase_amount. One qualifying country/customer pair per row; round display only. Final country ASC, country_rank ASC, customer_id ASC.

**Fictional example.** Fictional country totals 15000/12000/12000 retain ranks 1/2/2.

### Initial attempt excerpt

```sql
-- Two-CTE RANK version was correct on submission.
```

### Final query recorded in the journal

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
purchase_rank AS (
    SELECT country,
           RANK() OVER (PARTITION BY country ORDER BY purchase_amount DESC) AS country_rank,
           customer_id, item_count,
           ROUND(purchase_amount, 2) AS total_purchase_amount
    FROM country_purchase
)
SELECT country, country_rank, customer_id, item_count, total_purchase_amount
FROM purchase_rank
WHERE country_rank <= 2
ORDER BY country ASC, country_rank ASC, customer_id ASC;
```

### Recorded output (source excerpt)

| country | country_rank | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- | --- |
| Australia | 1 | 12415 | 714 | 124914.53 |
| Australia | 2 | 12431 | 181 | 5514.67 |
| Austria | 1 | 12360 | 129 | 2662.06 |
| Austria | 2 | 12865 | 95 | 1568.23 |
| Bahrain | 1 | 12355 | 13 | 459.40 |
| Bahrain | 2 | 12353 | 4 | 89.00 |
| Belgium | 1 | 12362 | 266 | 5226.23 |
| Belgium | 2 | 12449 | 191 | 4067.29 |
| Brazil | 1 | 12769 | 32 | 1143.60 |
| Canada | 1 | 17444 | 135 | 2940.04 |
| Canada | 2 | 17443 | 1 | 534.24 |
| Channel Islands | 1 | 14936 | 364 | 8137.02 |
| Channel Islands | 2 | 14930 | 128 | 2372.86 |
| Cyprus | 1 | 12359 | 248 | 6372.58 |
| Cyprus | 2 | 12370 | 159 | 3268.49 |
| Czech Republic | 1 | 12781 | 25 | 826.74 |
| Denmark | 1 | 12435 | 36 | 7829.89 |
| Denmark | 2 | 12406 | 105 | 3415.30 |
| EIRE | 1 | 14911 | 5675 | 143825.06 |
| EIRE | 2 | 14156 | 1400 | 117379.63 |
| European Community | 1 | 15108 | 60 | 1300.25 |
| Finland | 1 | 12428 | 294 | 7956.46 |
| Finland | 2 | 12664 | 37 | 4881.88 |
| France | 1 | 12731 | 274 | 18895.91 |
| France | 2 | 12678 | 165 | 17628.46 |
| Germany | 1 | 12471 | 460 | 19824.05 |

Only the supplied first 26 rows; full historical count/runtime not supplied.

### Correction and interpretation

RANK uses unrounded amount; rounding is display-only. Customer ID is a display tie-breaker, not part of RANK, so equal amounts share rank. The provided output is partial and its footer is not inferred.

## Exercise 6 — Question 3 case 2: one CTE with grouping and RANK

Original question/case: 3-2.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Same Question 3 ties, scope, output and order. Alternative combines aggregation and RANK in one CTE, then filters rank <=2 outside. No 10000 threshold; round display only.

**Fictional example.** The same fictional ties retain all three with one CTE.

### Final query recorded in the journal

```sql
WITH ranked_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount,
           RANK() OVER (
               PARTITION BY country
               ORDER BY SUM(quantity * unit_price) DESC
           ) AS country_rank
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
)
SELECT country, country_rank, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM ranked_purchase
WHERE country_rank <= 2
ORDER BY country ASC, country_rank ASC, customer_id ASC;
```

### Recorded output (source excerpt)

| country | country_rank | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- | --- |
| Australia | 1 | 12415 | 714 | 124914.53 |
| Australia | 2 | 12431 | 181 | 5514.67 |
| Austria | 1 | 12360 | 129 | 2662.06 |
| Austria | 2 | 12865 | 95 | 1568.23 |
| Bahrain | 1 | 12355 | 13 | 459.40 |
| Bahrain | 2 | 12353 | 4 | 89.00 |
| Belgium | 1 | 12362 | 266 | 5226.23 |
| Belgium | 2 | 12449 | 191 | 4067.29 |
| Brazil | 1 | 12769 | 32 | 1143.60 |
| Canada | 1 | 17444 | 135 | 2940.04 |
| Canada | 2 | 17443 | 1 | 534.24 |
| Channel Islands | 1 | 14936 | 364 | 8137.02 |
| Channel Islands | 2 | 14930 | 128 | 2372.86 |
| Cyprus | 1 | 12359 | 248 | 6372.58 |
| Cyprus | 2 | 12370 | 159 | 3268.49 |
| Czech Republic | 1 | 12781 | 25 | 826.74 |
| Denmark | 1 | 12435 | 36 | 7829.89 |
| Denmark | 2 | 12406 | 105 | 3415.30 |
| EIRE | 1 | 14911 | 5675 | 143825.06 |
| EIRE | 2 | 14156 | 1400 | 117379.63 |
| European Community | 1 | 15108 | 60 | 1300.25 |
| Finland | 1 | 12428 | 294 | 7956.46 |
| Finland | 2 | 12664 | 37 | 4881.88 |
| France | 1 | 12731 | 274 | 18895.91 |
| France | 2 | 12678 | 165 | 17628.46 |
| Germany | 1 | 12471 | 460 | 19824.05 |
| Germany | 2 | 12621 | 467 | 13689.67 |
| Greece | 1 | 14439 | 32 | 2661.24 |
| Greece | 2 | 12717 | 55 | 1030.98 |
| Iceland | 1 | 12347 | 182 | 4310.00 |
| Israel | 1 | 12688 | 171 | 4873.81 |
| Israel | 2 | 12653 | 43 | 2209.85 |
| Italy | 1 | 12594 | 118 | 3338.22 |
| Italy | 2 | 12578 | 114 | 2794.51 |
| Japan | 1 | 12753 | 197 | 21429.39 |
| Japan | 2 | 12798 | 8 | 6977.04 |
| Lebanon | 1 | 12764 | 45 | 1693.88 |
| Lithuania | 1 | 15332 | 35 | 1661.06 |
| Malta | 1 | 17828 | 67 | 1820.09 |
| Malta | 2 | 15480 | 45 | 905.50 |
| Netherlands | 1 | 14646 | 2076 | 280206.02 |
| Netherlands | 2 | 12759 | 95 | 1531.44 |
| Norway | 1 | 12433 | 420 | 13375.87 |
| Norway | 2 | 12432 | 108 | 5059.32 |
| Poland | 1 | 12779 | 149 | 3981.36 |
| Poland | 2 | 12576 | 88 | 1315.83 |
| Portugal | 1 | 12757 | 371 | 7857.10 |
| Portugal | 2 | 12766 | 310 | 6989.63 |
| RSA | 1 | 12446 | 57 | 1002.31 |
| Saudi Arabia | 1 | 12565 | 9 | 145.92 |
| Singapore | 1 | 12744 | 222 | 21279.29 |
| Spain | 1 | 12540 | 478 | 13400.24 |
| Spain | 2 | 12557 | 33 | 11990.96 |
| Sweden | 1 | 17404 | 198 | 31906.82 |
| Sweden | 2 | 12483 | 75 | 2484.98 |
| Switzerland | 1 | 12409 | 109 | 11072.67 |
| Switzerland | 2 | 12451 | 354 | 9035.52 |
| USA | 1 | 12607 | 101 | 1579.51 |
| USA | 2 | 12646 | 45 | 1346.97 |
| United Arab Emirates | 1 | 12739 | 38 | 1013.04 |
| United Arab Emirates | 2 | 17829 | 30 | 889.24 |
| United Kingdom | 1 | 18102 | 431 | 259657.30 |
| United Kingdom | 2 | 17450 | 337 | 194550.79 |
| Unspecified | 1 | 16320 | 56 | 1038.46 |
| Unspecified | 2 | 12363 | 23 | 552.00 |

User terminal: 65 rows / 2.47 sec.

### Correction and interpretation

This is execution of a supplied one-CTE alternative. Combine aggregation and RANK, but filter computed ranks in an outer query. Preserve this alongside the two-CTE approach.

## Exercise 7 — At most two customers per country

Original question/case: 4.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Use ROW_NUMBER within country, unrounded amount DESC, customer_id ASC. Keep numbers 1 and 2 only, no extra tied customers and no 10000 threshold; countries with one customer yield one. Return country, selection_no, customer_id, item_count, total_purchase_amount. Round display only. Final country ASC, selection_no ASC.

**Fictional example.** Fictional C01:15000, C02:12000, C03:12000 retain C01/C02 only.

### Initial attempt excerpt

```sql
RANK() OVER (PARTITION BY country ORDER BY purchase_amount DESC) AS country_rank
-- This keeps boundary ties and does not enforce at most two.
```

### Final query recorded in the journal

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
purchase_rank AS (
    SELECT country,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS selection_no,
           customer_id, item_count,
           ROUND(purchase_amount, 2) AS total_purchase_amount
    FROM country_purchase
)
SELECT country, selection_no, customer_id, item_count, total_purchase_amount
FROM purchase_rank
WHERE selection_no <= 2
ORDER BY country ASC, selection_no ASC;
```

### Recorded output (source excerpt)

No output was supplied for the final corrected query; no historical table is invented.

Final corrected SQL only; no user output/runtime supplied.

### Correction and interpretation

The first attempt reused RANK, potentially retaining more than two boundary ties. Correct to ROW_NUMBER with customer-ID tie-breaking, selection_no alias/filter and output order. The final SQL is valid by review, but no corrected output was shared; do not call it user-execution verified.

## Exercise 8 — Country summaries of the selected top two customers

Original question/case: 5.

### Table and row grain

sales_items is a sales-line view, one source invoice-item line per row, not one invoice or one unit. Required fields: source_row_id INT non-NULL row identifier; country VARCHAR(100) non-NULL purchase-record country; customer_id VARCHAR(20) nullable (unidentified customer); quantity INT non-NULL units; unit_price DECIMAL(16,6) non-NULL GBP per unit. The view keeps quantity > 0, unit_price > 0 and invoice_no not starting C. These purchase totals are not return-adjusted net revenue, and country is not established permanent residence.

### Question and conditions

Use only sales_items over the full period; exclude NULL customer_id and group by country/customer. Purchase amount is SUM(quantity * unit_price); item_count counts line rows, not quantity or invoices. Split a customer across purchase countries.

Choose at most two customers per country using ROW_NUMBER ordered by unrounded amount DESC then customer_id ASC. No 10000 threshold. Then count selected customers and sum their unrounded customer totals by country; round only the final sum. A single-customer country contributes one. Return country, selected_customer_count, top2_purchase_amount, one country summary per row. Final unrounded sum DESC, country ASC.

**Fictional example.** Fictional A has C01:15000, C02:12000, C03:12000: select C01/C02, count 2 and sum 27000. B with one 9000 customer returns count 1 and sum 9000.

### Initial attempt excerpt

```sql
COUNT(*) AS selected_customer_count
-- Inside GROUP BY country, customer_id this counts item lines, not selected customers.
COUNT(SUM(quantity * unit_price)) AS selected_customer_count
-- Nested aggregate at one query level cannot express the required country summary.
```

### Final query recorded in the journal

```sql
WITH customer_purchase AS (
    SELECT country, customer_id,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
rn_customer AS (
    SELECT country, customer_id, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM customer_purchase
)
SELECT country,
       COUNT(*) AS selected_customer_count,
       ROUND(SUM(purchase_amount), 2) AS top2_purchase_amount
FROM rn_customer
WHERE rn <= 2
GROUP BY country
ORDER BY SUM(purchase_amount) DESC, country ASC;
```

### Recorded output (source excerpt)

| country | selected_customer_count | top2_purchase_amount |
| --- | --- | --- |
| United Kingdom | 2 | 454208.09 |
| Netherlands | 2 | 281737.46 |
| EIRE | 2 | 261204.69 |
| Australia | 2 | 130429.20 |
| France | 2 | 36524.37 |
| Sweden | 2 | 34391.80 |
| Germany | 2 | 33513.72 |
| Japan | 2 | 28406.43 |
| Spain | 2 | 25391.20 |
| Singapore | 1 | 21279.29 |
| Switzerland | 2 | 20108.19 |
| Norway | 2 | 18435.19 |
| Portugal | 2 | 14846.73 |
| Finland | 2 | 12838.34 |
| Denmark | 2 | 11245.19 |
| Channel Islands | 2 | 10509.88 |
| Cyprus | 2 | 9641.07 |
| Belgium | 2 | 9293.52 |
| Israel | 2 | 7083.66 |
| Italy | 2 | 6132.73 |
| Poland | 2 | 5297.19 |
| Iceland | 1 | 4310.00 |
| Austria | 2 | 4230.29 |
| Greece | 2 | 3692.22 |
| Canada | 2 | 3474.28 |
| USA | 2 | 2926.48 |
| Malta | 2 | 2725.59 |
| United Arab Emirates | 2 | 1902.28 |
| Lebanon | 1 | 1693.88 |
| Lithuania | 1 | 1661.06 |
| Unspecified | 2 | 1590.46 |
| European Community | 1 | 1300.25 |
| Brazil | 1 | 1143.60 |
| RSA | 1 | 1002.31 |
| Czech Republic | 1 | 826.74 |
| Bahrain | 2 | 548.40 |
| Saudi Arabia | 1 | 145.92 |

User terminal: 37 rows / 2.43 sec.

### Correction and interpretation

The initial attempt treated a per-customer line COUNT as a selected-customer count and tried COUNT(SUM(...)) at one level. Other attempts dropped the amount between CTEs or filtered rn at its calculation level. The corrected design aggregates customer amounts, numbers rows, selects at most two, then re-aggregates by country. Round the final sum only.

## Understanding Question 5

Fictional customer totals: A/C01=15000, A/C02=12000, A/C03=12000, B/C04=9000. The first CTE has one country/customer row. Number those same rows: A gets 1/2/3 (C02 wins the tie); B gets 1. Keep rn<=2, then GROUP BY country. A has COUNT(*)=2 and SUM(purchase_amount)=27000; B has count 1 and sum 9000. COUNT now counts customer rows rather than original invoice-item rows. Do not count while assigning row numbers; preserve amount into the next step. Round the final sum only.

In Question 2, the maximum-value/lower-bound filter is equivalent before or after numbering, but this is not a general window-filter rule. The prior latest-date/amount case differs. One-CTE alternatives combine aggregation and window calculation, while window-result filtering still needs an outer level. No delayed independent re-solve has yet been verified.
