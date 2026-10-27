-- Recorded final queries. Read the matching lesson and schema before running.

-- Exercise 1
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;

-- Exercise 2
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;

-- Exercise 3
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT transaction_date) AS active_day_count,
    ROUND(SUM(transaction_amount), 2) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING active_day_count >= 3
ORDER BY active_day_count DESC, total_transaction_amount DESC, customer_id ASC;

-- Exercise 4
SELECT COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT transaction_date) AS active_day_count,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING active_day_count >= 3
) AS active_customer_id;

-- Exercise 5
SELECT ROUND(AVG(total_transaction_amount), 2) AS avg_customer_total
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT transaction_date) AS active_day_count,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING active_day_count >= 3
) AS active_customer;
