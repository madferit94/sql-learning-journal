-- Day17: historical final queries from Notion. Not rerun for publication.

-- Exercise 1: Monthly quantities and sales amounts
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS purchase_month,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FROM sales_items
GROUP BY purchase_month
ORDER BY purchase_month ASC;

-- Exercise 2: Monthly high-value item percentage
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

-- Exercise 3: Country sales in 2011
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

-- Exercise 4: Count customers purchasing in at least three months
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

-- Exercise 5: Mean annual total for qualifying customers
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
