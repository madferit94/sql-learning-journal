-- Scoped MySQL 8.4.11 audit: 2026-11-02. See docs/audit.en.md.

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
    SUM(
        CASE
            WHEN transaction_amount >= 5000 THEN transaction_amount
            ELSE 0
        END
    ) AS high_amount_total,
    ROUND(
        COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(transaction_date) * 100,
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
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_amount >= 10000
   AND active_day_count >= 3
ORDER BY
    active_day_count DESC,
    total_transaction_amount DESC,
    customer_id ASC;

-- Exercise 4
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
ORDER BY total_amount DESC, customer_id ASC;

-- Exercise 5
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
WHERE total_amount >= 10000
ORDER BY total_amount DESC, customer_id ASC;
