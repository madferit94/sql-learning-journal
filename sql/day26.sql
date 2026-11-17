-- Day26: five questions and eight retained query variants.
-- Labels: 1, 2-1, 2-2, 2-3, 3-1, 3-2, 4, 5.
USE retail_study;

-- Question/case 1
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

-- Question/case 2-1
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

-- Question/case 2-2
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

-- Question/case 2-3
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

-- Question/case 3-1
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

-- Question/case 3-2
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

-- Question/case 4
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

-- Question/case 5
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
