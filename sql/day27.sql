-- Day27: five questions, eight query variants.
USE finance;

-- Question/case 1
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       COUNT(*) AS transaction_count,
       COUNT(DISTINCT customer_id) AS customer_count,
       SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month;

-- Question/case 2
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       SUM(transaction_amount) AS total_transaction_amount,
       LAG(SUM(transaction_amount)) OVER (
           ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')
       ) AS previous_month_amount,
       SUM(transaction_amount) - LAG(SUM(transaction_amount)) OVER (
           ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')
       ) AS amount_change
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month;

-- Question/case 3-1
WITH month_amount AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
           SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY transaction_month
),
lag_amount AS (
    SELECT transaction_month, total_transaction_amount,
           LAG(total_transaction_amount) OVER (
               ORDER BY transaction_month
           ) AS previous_month_amount
    FROM month_amount
)
SELECT transaction_month, total_transaction_amount, previous_month_amount,
       ROUND((total_transaction_amount - previous_month_amount)
             / NULLIF(previous_month_amount, 0) * 100, 2) AS amount_change_rate
FROM lag_amount
ORDER BY transaction_month;

-- Question/case 3-2
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       SUM(transaction_amount) AS total_transaction_amount,
       LAG(SUM(transaction_amount)) OVER month_order AS previous_month_amount,
       ROUND(
           (SUM(transaction_amount) - LAG(SUM(transaction_amount)) OVER month_order)
           / NULLIF(LAG(SUM(transaction_amount)) OVER month_order, 0) * 100,
           2
       ) AS amount_change_rate
FROM finance.bank_transactions
GROUP BY transaction_month
WINDOW month_order AS (ORDER BY MIN(transaction_date))
ORDER BY transaction_month;

-- Question/case 3-3: display-only variant
WITH month_amount AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
           SUM(transaction_amount) AS total_transaction_amount
    FROM finance.bank_transactions
    GROUP BY transaction_month
),
lag_amount AS (
    SELECT transaction_month, total_transaction_amount,
           LAG(total_transaction_amount) OVER (
               ORDER BY transaction_month
           ) AS previous_month_amount
    FROM month_amount
)
SELECT transaction_month, total_transaction_amount,
       IFNULL(previous_month_amount, 0.00) AS previous_month_amount,
       IFNULL(ROUND((total_transaction_amount - previous_month_amount)
                    / NULLIF(previous_month_amount, 0) * 100, 2), 0.00) AS amount_change_rate
FROM lag_amount
ORDER BY transaction_month;

-- Question/case 4-1
WITH customer_daily_amount AS (
    SELECT customer_id,
           DATE_FORMAT(transaction_date, '%Y-%m-%d') AS transaction_date,
           SUM(transaction_amount) AS daily_amount
    FROM bank_transactions
    GROUP BY customer_id, transaction_date
)
SELECT customer_id, transaction_date, daily_amount,
       LAG(daily_amount) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_day_amount
FROM customer_daily_amount
ORDER BY customer_id, transaction_date
LIMIT 20;

-- Question/case 4-2
WITH customer_daily_amount AS (
    SELECT customer_id, transaction_date, SUM(transaction_amount) AS daily_amount
    FROM finance.bank_transactions
    GROUP BY customer_id, transaction_date
)
SELECT customer_id, transaction_date, daily_amount,
       LAG(daily_amount) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_day_amount
FROM customer_daily_amount
ORDER BY customer_id, transaction_date
LIMIT 20;

-- Question/case 5
WITH customer_daily_amount AS (
    SELECT customer_id, transaction_date, SUM(transaction_amount) AS daily_amount
    FROM finance.bank_transactions
    GROUP BY customer_id, transaction_date
),
prev_amount AS (
    SELECT customer_id, transaction_date, daily_amount,
           LAG(daily_amount) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           ) AS previous_day_amount
    FROM customer_daily_amount
)
SELECT customer_id,
       COUNT(CASE WHEN previous_day_amount < daily_amount THEN 1 END) AS increase_day_count
FROM prev_amount
GROUP BY customer_id
HAVING increase_day_count >= 2
ORDER BY increase_day_count DESC, customer_id
LIMIT 20;
