# Day 22 — F1 review and e-commerce CTE/customer rankings

[한국어](../ko/day22.md) · [Index](../../README.md) · [Audit](../../docs/audit.en.md)

Exercises 1–2 use f1_study: Austin 11396 for Exercise 1, all 19 main races through Mexico 11404 for Exercise 2. Exercises 3–5 use retail_study. Sprints, practice and qualifying are excluded. No 40-lap condition applies. Recorded outputs below are the final submitted executions; the later audit checked all five separately.

```bash
mysql -u root -p
```

```sql
-- Exercises 1–2
USE f1_study;
-- Exercises 3–5
USE retail_study;
```

## Exercise 1 — Austin team totals

### Tables and row grain

drivers: one row per session/driver; session_key INT, driver_number INT, full_name VARCHAR(100), team_name VARCHAR(100). race_results: one row per session/driver result; session_key INT, driver_number INT, completed_laps INT, points DECIMAL(8,2). Join both session_key and driver_number. These key fields, laps and points are non-NULL in the checked data.

**Question and conditions.** Join drivers and race_results using session_key and driver_number. For Austin session 11396 only, return team_name, driver_count, total_laps and total_points. Include unclassified, retired and zero-point records; there is no lap cutoff. Sort total_points descending, then team_name ascending. One output row is a team.

**Example — fictional.** Fictional example: two drivers completing 56 laps each and scoring 25 and 18 points produce driver_count 2, total_laps 112 and total_points 43.00.

### Final query recorded in the journal

```sql
SELECT
    d.team_name,
    COUNT(*) AS driver_count,
    SUM(completed_laps) AS total_laps,
    SUM(points) AS total_points
FROM drivers d
JOIN race_results r
    ON r.session_key = d.session_key
   AND r.driver_number = d.driver_number
WHERE r.session_key = 11396
GROUP BY d.team_name
ORDER BY total_points DESC, team_name ASC;
```

### Recorded output (source excerpt)

| team\_name | driver\_count | total\_laps | total\_points |
| --- | --- | --- | --- |
| Ferrari | 2 | 112 | 30.00 |
| Mercedes | 2 | 112 | 29.00 |
| Red Bull Racing | 2 | 112 | 23.00 |
| McLaren | 2 | 112 | 16.00 |
| Racing Bulls | 2 | 111 | 2.00 |
| Alpine | 2 | 91 | 1.00 |
| Aston Martin | 2 | 110 | 0.00 |
| Audi | 2 | 111 | 0.00 |
| Cadillac | 2 | 103 | 0.00 |
| Haas F1 Team | 2 | 79 | 0.00 |
| Williams | 2 | 110 | 0.00 |

Recorded execution: 11 rows in 0.07 seconds.

### Key concept and interpretation

Correct composite-key joins make each joined row one driver result in the selected race. COUNT(*) is therefore a driver count within the team. Comparing r.driver_number to itself would not match the two entities and can multiply rows.

## Exercise 2 — Drivers with at least 100 main-race points

### Tables and row grain

drivers: one row per session/driver; session_key INT, driver_number INT, full_name VARCHAR(100), team_name VARCHAR(100). race_results: one row per session/driver result; session_key INT, driver_number INT, completed_laps INT, points DECIMAL(8,2). Join both session_key and driver_number. These key fields, laps and points are non-NULL in the checked data.

**Question and conditions.** Use a driver_totals CTE across all 19 main races through Mexico. Group by driver number and name, combining team changes. Count every result row and sum points, including retirements and zero-point records. Return driver_number, full_name, race_count and total_points for totals >= 100. Sort total_points descending, then driver_number ascending. One output row is a qualifying driver.

**Example — fictional.** Fictional example: a driver with 150 points from 19 races and one with exactly 100 from 17 races both qualify. There is no minimum race count.

### Final query recorded in the journal

```sql
WITH driver_totals AS (
    SELECT
        d.driver_number,
        d.full_name,
        COUNT(*) race_count,
        SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name
)
SELECT driver_number, full_name, race_count, total_points
FROM driver_totals
WHERE total_points >= 100
ORDER BY total_points DESC, driver_number ASC;
```

### Recorded output (source excerpt)

| driver\_number | full\_name | race\_count | total\_points |
| --- | --- | --- | --- |
| 12 | Kimi ANTONELLI | 19 | 349.00 |
| 3 | Max VERSTAPPEN | 19 | 241.00 |
| 44 | Lewis HAMILTON | 19 | 232.00 |
| 63 | George RUSSELL | 19 | 216.00 |
| 16 | Charles LECLERC | 19 | 211.00 |
| 1 | Lando NORRIS | 19 | 188.00 |
| 81 | Oscar PIASTRI | 19 | 123.00 |
| 6 | Isack HADJAR | 16 | 107.00 |

Recorded execution: 8 rows in 0.00 seconds.

### Key concept and interpretation

The CTE produces one row per driver. The outer WHERE filters the already-calculated total_points; no second GROUP BY is necessary. Main-race points exclude Sprint points.

## Exercise 3 — Customers with at least GBP 1000 in purchases

### Tables and row grain

sales_items: one row is one invoice item line, not one invoice or one physical item. customer_id VARCHAR(20) is nullable (unidentified customer), country VARCHAR(100) is non-NULL, quantity INT and unit_price DECIMAL(16,6) are non-NULL. unit_price is GBP per unit. This view retains positive quantity/price and non-cancellation invoice lines. A line amount is quantity * unit_price; totals are positive sales, not net revenue.

**Question and conditions.** Use only sales_items across all periods and exclude NULL customer_id. In customer_totals, count purchase-item rows per customer and sum quantity * unit_price. Return customer_id, item_count and total_purchase_amount for unrounded totals >= GBP 1000. Round only the displayed total to two decimals. Sort the original unrounded total descending, then customer_id ascending. One output row is a qualifying customer.

**Example — fictional.** Fictional example: customer A has 12 purchase lines totaling GBP 2500.00. item_count is 12; it is not the sum of item quantities or the number of invoices.

### Final query recorded in the journal

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        COUNT(*) AS item_count,
        SUM(quantity * unit_price) AS total_purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    customer_id,
    item_count,
    ROUND(total_purchase_amount, 2) AS total_purchase_amount
FROM customer_totals
WHERE total_purchase_amount >= 1000
ORDER BY customer_totals.total_purchase_amount DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| customer\_id | item\_count | total\_purchase\_amount |
| --- | --- | --- |
| 14646 | 2076 | 280206.02 |
| 18102 | 431 | 259657.30 |
| 17450 | 337 | 194550.79 |
| 16446 | 3 | 168472.50 |
| 14911 | 5675 | 143825.06 |
| 12415 | 714 | 124914.53 |
| 14156 | 1400 | 117379.63 |
| 17511 | 963 | 91062.38 |
| 16029 | 242 | 81024.84 |
| 12346 | 1 | 77183.60 |

Recorded excerpt only. The original total result count and execution time were not supplied; later audit counts are reported separately.

### Key concept and interpretation

COUNT(quantity * unit_price) also counts every row in this non-NULL dataset; COUNT(*) expresses row counting directly. WHERE customer_id IS NOT NULL alone does not establish whether other fields are NULL. Qualifying ORDER BY with customer_totals uses the original total rather than the rounded output alias.

## Exercise 4 — Overall customer purchase ranking

### Tables and row grain

sales_items: one row is one invoice item line, not one invoice or one physical item. customer_id VARCHAR(20) is nullable (unidentified customer), country VARCHAR(100) is non-NULL, quantity INT and unit_price DECIMAL(16,6) are non-NULL. unit_price is GBP per unit. This view retains positive quantity/price and non-cancellation invoice lines. A line amount is quantity * unit_price; totals are positive sales, not net revenue.

**Question and conditions.** Use only sales_items, all periods and non-NULL customer IDs. In customer_totals, count purchase rows and sum quantity * unit_price per customer. Include all identified customers, with no minimum total. Use RANK on unrounded totals descending, keeping ties and gaps. Return purchase_rank, customer_id, item_count and total_purchase_amount (two display decimals). Sort rank ascending and customer ID ascending for ties. Sorting the original total descending then customer ID gives the same required order.

**Example — fictional.** Fictional example: totals 2500, 1200, 1200 and 900 produce ranks 1, 2, 2 and 4. Equal displayed totals do not prove equal original totals.

### Final query recorded in the journal

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        COUNT(*) AS item_count,
        SUM(quantity * unit_price) AS total_purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    RANK() OVER (ORDER BY total_purchase_amount DESC) AS purchase_rank,
    customer_id,
    item_count,
    ROUND(total_purchase_amount, 2) AS total_purchase_amount
FROM customer_totals
ORDER BY customer_totals.total_purchase_amount DESC, customer_id ASC;
```

### Recorded output (source excerpt)

| purchase\_rank | customer\_id | item\_count | total\_purchase\_amount |
| --- | --- | --- | --- |
| 1 | 14646 | 2076 | 280206.02 |
| 2 | 18102 | 431 | 259657.30 |
| 3 | 17450 | 337 | 194550.79 |
| 4 | 16446 | 3 | 168472.50 |
| 5 | 14911 | 5675 | 143825.06 |
| 6 | 12415 | 714 | 124914.53 |
| 7 | 14156 | 1400 | 117379.63 |
| 8 | 17511 | 963 | 91062.38 |
| 9 | 16029 | 242 | 81024.84 |
| 10 | 12346 | 1 | 77183.60 |

Recorded excerpt only. The original total result count and execution time were not supplied; later audit counts are reported separately.

### Key concept and interpretation

OVER ORDER BY computes ranks; the last ORDER BY controls display order. Customer ID is a display tie-breaker, not a ranking tie-breaker. The submitted last ORDER BY on unrounded total is equivalent to ascending purchase_rank.

## Exercise 5 — Within-country customer purchase ranking

### Tables and row grain

sales_items: one row is one invoice item line, not one invoice or one physical item. customer_id VARCHAR(20) is nullable (unidentified customer), country VARCHAR(100) is non-NULL, quantity INT and unit_price DECIMAL(16,6) are non-NULL. unit_price is GBP per unit. This view retains positive quantity/price and non-cancellation invoice lines. A line amount is quantity * unit_price; totals are positive sales, not net revenue.

**Question and conditions.** Use only sales_items across all periods; exclude NULL customer IDs. In country_customer_totals, group by country and customer_id, counting item rows and summing quantity * unit_price. The same customer in different countries forms separate groups. Use RANK within each country on original totals descending; equal totals tie and the next rank is skipped. No minimum total. Return country, country_rank, customer_id, item_count and total_purchase_amount (two display decimals). Sort country, country_rank and customer_id ascending. One row is one country/customer combination.

**Example — fictional.** Fictional example: France customers A/B have ranks 1/2 and Germany customers C/D also have ranks 1/2. The rank restarts in each country. Country is the purchase record country, not a verified permanent residence.

### Final query recorded in the journal

```sql
WITH country_customer_totals AS (
    SELECT
        country,
        customer_id,
        COUNT(*) AS item_count,
        SUM(quantity * unit_price) AS total_purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
)
SELECT
    country,
    RANK() OVER (
        PARTITION BY country
        ORDER BY total_purchase_amount DESC
    ) AS country_rank,
    customer_id,
    item_count,
    ROUND(total_purchase_amount, 2) AS total_purchase_amount
FROM country_customer_totals
ORDER BY country ASC, country_rank ASC, customer_id ASC;
```

### Recorded output (source excerpt)

| country | country\_rank | customer\_id | item\_count | total\_purchase\_amount |
| --- | --- | --- | --- | --- |
| Australia | 1 | 12415 | 714 | 124914.53 |
| Australia | 2 | 12431 | 181 | 5514.67 |
| Australia | 3 | 12388 | 100 | 2780.66 |
| Australia | 4 | 12424 | 30 | 1760.96 |
| Australia | 5 | 12393 | 64 | 1582.60 |
| Australia | 6 | 12434 | 50 | 806.14 |
| Australia | 7 | 12386 | 10 | 401.90 |
| Australia | 8 | 12422 | 21 | 386.20 |
| Australia | 9 | 16321 | 12 | 373.65 |
| Austria | 1 | 12360 | 129 | 2662.06 |
| Austria | 2 | 12865 | 95 | 1568.23 |
| Austria | 3 | 12818 | 14 | 1542.08 |

Recorded excerpt only. The original total result count and execution time were not supplied; later audit counts are reported separately.

### Key concept and interpretation

GROUP BY collapses lines to country/customer rows. PARTITION BY preserves those rows and restarts ranking by country. The final ORDER BY controls the country display sequence.

## COUNT and precision review

COUNT(*) counts rows even if some fields are NULL; COUNT(expression) counts non-NULL values and includes zero. For quantities 3, NULL and 0, COUNT(*) is 3, COUNT(quantity) is 2 and SUM(quantity) is 3. Excluding NULL customer IDs does not remove NULL amounts by itself, although this view separately guarantees non-NULL quantities/prices.

Totals 1000.001 and 1000.004 both display as 1000.00 but the second is larger. Rank/filter/sort the original values and round the display only. PARTITION BY country restarts ranking; GROUP BY country, customer_id defines the aggregated row.

## Verification and next review

The later audit reproduced 11/8/1668/4338/4346 result rows for Exercises 1–5. These new counts are not substituted for missing historical output metadata. Revisit CTE row grain, COUNT/NULL, original versus displayed amounts, ranking ties and composite join keys without opening the final queries.
