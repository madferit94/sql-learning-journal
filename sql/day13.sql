-- Historical final queries transcribed from the study journal. Not rerun for publication.

-- Exercise 1: Customers with multiple high-value transactions
SELECT customer_id,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    SUM(CASE WHEN transaction_amount >= 5000 THEN transaction_amount ELSE 0 END) AS high_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING high_amount_count >= 2
ORDER BY high_amount_total DESC, customer_id ASC;

-- Exercise 2: Total and small-value transactions
SELECT customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    SUM(CASE WHEN transaction_amount < 1000 THEN transaction_amount ELSE 0 END) AS small_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_count DESC, customer_id ASC;

-- Exercise 3: Small-value transaction percentage
SELECT customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    ROUND(
        COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) / COUNT(*) * 100,
        2
    ) AS small_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_rate DESC, customer_id ASC;

-- Exercise 4: Average customer total
SELECT ROUND(AVG(total_transaction_amount), 2) AS avg_customer_total
FROM (
    SELECT customer_id,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
) AS customer_totals;

-- Exercise 5: Customers with totals of at least 10,000
SELECT COUNT(*) AS customer_count
FROM (
    SELECT customer_id,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING total_transaction_amount >= 10000
) AS qualifying_customers;
