-- Historical final queries transcribed from the study journal. Not rerun for publication.

-- Exercise 1: Active customers
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 5
ORDER BY total_transaction_amount DESC, customer_id ASC;

-- Exercise 2: Repeated transactions of at least 1,000
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
WHERE transaction_amount >= 1000
GROUP BY customer_id
HAVING transaction_count >= 3
ORDER BY transaction_count DESC, customer_id ASC;

-- Exercise 3: High-value transaction counts
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_count DESC, customer_id ASC;

-- Exercise 4: High-value transaction percentage
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        SUM(CASE WHEN transaction_amount >= 5000 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_rate DESC, customer_id ASC;

-- Exercise 5: Customer distribution by transaction count
SELECT
    transaction_count,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count
    FROM bank_transactions
    GROUP BY customer_id
) AS customer_transactions
GROUP BY transaction_count
ORDER BY transaction_count ASC;
