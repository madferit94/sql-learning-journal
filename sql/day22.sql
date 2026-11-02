-- Final exercise queries recorded in the learning journal.
-- Audit: docs/audit.en.md (2026-11-02); historical snapshot scopes must be preserved.

-- Exercises 1–2: USE f1_study; Exercises 3–5: USE retail_study;


-- Exercise 1
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


-- Exercise 2
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


-- Exercise 3
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


-- Exercise 4
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


-- Exercise 5
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
