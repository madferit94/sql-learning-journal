-- Day 09: Olist joins and two-stage aggregation
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day09.md for questions, context and known limitations.

-- Exercise 1: Count 2018 purchases by state, ordered by count descending then state ascending.
SELECT c.customer_state,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
ORDER BY order_count DESC, c.customer_state ASC;

-- Exercise 2: Across all available periods, find customers with at least two orders, ordered by count descending then unique identifier ascending.
SELECT c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC, customer_unique_id ASC;

-- Exercise 3: Count delivered orders purchased in 2018 by state, keeping at least five hundred.
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

-- Exercise 4: Count delivered orders purchased in 2018 by state and city, keeping at least three hundred.
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

-- Exercise 5: Count repeat customers by state across all available periods.
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

