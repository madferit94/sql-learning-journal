-- Day 05: Customer identifiers and joins
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day05.md for questions, context and known limitations.

-- Exercise 1: Check whether customer_id occurs more than once in customers.
SELECT customer_id,
       COUNT(*) AS customer_count
FROM customers
GROUP BY customer_id
HAVING customer_count >= 2
ORDER BY customer_count DESC;

-- Exercise 2: Find the ten most frequent customer_unique_id values with at least two customer records.
SELECT customer_unique_id,
       COUNT(*) AS customer_count
FROM customers
GROUP BY customer_unique_id
HAVING customer_count >= 2
ORDER BY customer_count DESC
LIMIT 10;

-- Exercise 3: Find the ten states with the most delivered orders.
SELECT customer_state, COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY order_count DESC
LIMIT 10;

-- Exercise 4: Count delivered orders by purchase year and state; sort year ascending and count descending, returning twenty rows.
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

-- Exercise 5: Compare delivered-order counts before and after joining customers.
SELECT COUNT(*) AS joined_delivered_count
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered';

