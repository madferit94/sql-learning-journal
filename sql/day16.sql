-- Historical final queries transcribed from the study journal. Not rerun for publication.

-- Exercise 1: Country quantities and sales amounts
SELECT country, SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FROM sales_items
GROUP BY country
HAVING total_quantity >= 1000
ORDER BY total_sales_amount DESC, country ASC;

-- Exercise 2: High-value item percentage
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

-- Exercise 3: Customer quantities and purchases
SELECT h.customer_id, COUNT(*) AS item_count,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.quantity * s.unit_price), 2) AS total_purchase_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
WHERE h.customer_id IS NOT NULL
GROUP BY h.customer_id
HAVING total_quantity >= 100
ORDER BY total_purchase_amount DESC, h.customer_id ASC;

-- Exercise 4: Count customers with at least GBP 1,000
SELECT COUNT(*) AS customer_count
FROM (
    SELECT SUM(quantity * unit_price) AS price
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING price >= 1000
) AS count;

-- Exercise 5: Average qualifying customer total
SELECT ROUND(AVG(price), 2) AS avg_customer_total
FROM (
    SELECT SUM(quantity * unit_price) AS price
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING price >= 1000
) AS count;
