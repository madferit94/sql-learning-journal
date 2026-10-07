-- Day 04: Olist order aggregation
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day04.md for questions, context and known limitations.

-- Exercise 1: Show the ten earliest purchases among delivered orders.
SELECT order_id, order_status, order_purchase_timestamp
FROM orders
WHERE order_status = 'delivered'
ORDER BY order_purchase_timestamp
LIMIT 10;

-- Exercise 2: Count orders by status, descending.
SELECT order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- Exercise 3: Count delivered orders by purchase year, ascending.
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year;

-- Exercise 4: Count all orders by purchase year, keeping years with at least 1,000 orders and sorting by count descending.
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_year
HAVING order_count >= 1000
ORDER BY order_count DESC;

-- Exercise 5: For delivered orders, show each purchase year's count, first purchase and last purchase.
SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS order_count,
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year;

