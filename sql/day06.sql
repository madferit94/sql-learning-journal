-- Day 06: Transaction aggregation and CASE WHEN
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day06.md for questions, context and known limitations.

-- Exercise 1: Calculate the transaction count and total amount.
SELECT
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions;

-- Exercise 2: Calculate transaction count and total amount by transaction date, ascending.
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY transaction_date;

-- Exercise 3: Calculate daily count, total and average transaction amount, rounding the average to two decimals and sorting by average descending.
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY avg_transaction_amount DESC;

-- Exercise 4: Find customers with at least five transactions, ordered by count and then amount descending.
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 5
ORDER BY
    transaction_count DESC,
    total_transaction_amount DESC;

-- Exercise 5: Classify transactions as Small below 1,000, Medium from 1,000 to below 5,000, and Large at least 5,000; calculate count and total per band.
SELECT
    CASE
        WHEN transaction_amount < 1000 THEN 'Small'
        WHEN transaction_amount >= 1000
             AND transaction_amount < 5000 THEN 'Medium'
        WHEN transaction_amount >= 5000 THEN 'Large'
    END AS amount_category,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY amount_category
ORDER BY transaction_count DESC;

