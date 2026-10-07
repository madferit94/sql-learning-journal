-- Day 11: Conditional aggregation and subquery review
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day11.md for questions, context and known limitations.

-- Exercise 1: Count delivered orders purchased in 2017 by state, keeping at least one thousand and sorting count descending then state ascending.
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

-- Exercise 2: For 2018 purchases, show order counts and distinct customer counts by state, keeping at least one thousand distinct customers and sorting by customer count descending then state ascending.
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

-- Exercise 3: For 2018 purchases, show each state's total, delivered and canceled order counts, keeping at least one thousand total orders.
-- UNRESOLVED: source records ERROR 1064; no successful final output.
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

-- Exercise 4: Across all available periods, count repeat customers per state, keeping at least twenty.
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

-- Exercise 5: Calculate 2018 repeat-customer percentages by state, keeping at least one thousand customers.
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

