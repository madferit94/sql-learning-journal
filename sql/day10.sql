-- Day 10: Monthly metrics and repeat-customer rates
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day10.md for questions, context and known limitations.

-- Exercise 1: Count delivered orders purchased in 2017 by calendar month, ascending.
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS delivered_order_count
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2017
  AND order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month ASC;

-- Exercise 2: Count distinct customers purchasing in 2018 by state, keeping at least five hundred.
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

-- Exercise 3: Count 2018 orders by state and status for delivered and canceled orders, keeping combinations with at least fifty.
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

-- Exercise 4: Across all available periods, list customers with at least three orders and their first and last purchase times.
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

-- Exercise 5: Calculate each state's repeat-customer percentage across all available periods, keeping at least five hundred customers and rounding to two decimals.
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

