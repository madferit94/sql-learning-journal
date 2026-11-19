-- Day28: five questions and two versions of Question 5.
USE finance;

-- Question/case 1
WITH customer_dates AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
)
SELECT customer_id, transaction_date,
       LAG(transaction_date) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_transaction_date,
       DATEDIFF(transaction_date, LAG(transaction_date) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       )) AS days_since_previous
FROM customer_dates
ORDER BY customer_id ASC, transaction_date ASC
LIMIT 20;

-- Question/case 2
WITH active_day AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_days AS (
    SELECT customer_id,
           DATEDIFF(transaction_date, LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           )) AS days_since_previous
    FROM active_day
)
SELECT customer_id, COUNT(*) AS active_day_count,
       ROUND(AVG(days_since_previous), 2) AS avg_days_between_transactions
FROM prev_days
GROUP BY customer_id
HAVING active_day_count >= 3
ORDER BY AVG(days_since_previous) DESC, customer_id
LIMIT 20;

-- Question/case 3
WITH active_day AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_days AS (
    SELECT customer_id, transaction_date,
           LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           ) AS previous_transaction_date
    FROM active_day
)
SELECT customer_id, transaction_date, previous_transaction_date,
       DATEDIFF(transaction_date, previous_transaction_date) AS days_since_previous
FROM prev_days
WHERE DATEDIFF(transaction_date, previous_transaction_date) >= 30
ORDER BY days_since_previous DESC, customer_id ASC, transaction_date ASC
LIMIT 20;

-- Question/case 4
WITH active_customer AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_day AS (
    SELECT customer_id, transaction_date,
           DATEDIFF(transaction_date, LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           )) AS previous_date
    FROM active_customer
)
SELECT customer_id, COUNT(previous_date) AS long_gap_count,
       MAX(previous_date) AS longest_gap_days
FROM prev_day
WHERE previous_date >= 30
GROUP BY customer_id
HAVING long_gap_count >= 2
ORDER BY long_gap_count DESC, longest_gap_days DESC, customer_id ASC
LIMIT 20;

-- Question/case 5-1
WITH customer_date AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM finance.bank_transactions
),
prev_day AS (
    SELECT
        customer_id,
        transaction_date,
        LAG(transaction_date) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_date
    FROM customer_date
),
gap_count AS (
    SELECT
        customer_id,
        COUNT(previous_date) AS total_gap_count,
        COUNT(
            CASE WHEN DATEDIFF(transaction_date, previous_date) >= 30
                 THEN 1
            END
        ) AS long_gap_count
    FROM prev_day
    GROUP BY customer_id
    HAVING COUNT(*) >= 3
)
SELECT
    customer_id,
    total_gap_count,
    long_gap_count,
    ROUND(long_gap_count / NULLIF(total_gap_count, 0) * 100, 2) AS long_gap_rate
FROM gap_count
ORDER BY long_gap_count / NULLIF(total_gap_count, 0) DESC,
         long_gap_count DESC,
         customer_id ASC
LIMIT 20;

-- Question/case 5-2
WITH customer_date AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM finance.bank_transactions
),
prev_day AS (
    SELECT
        customer_id,
        transaction_date,
        LAG(transaction_date) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_date
    FROM customer_date
),
gap_count AS (
    SELECT
        customer_id,
        COUNT(previous_date) AS total_gap_count,
        COUNT(
            CASE WHEN DATEDIFF(transaction_date, previous_date) >= 30
                 THEN 1
            END
        ) AS long_gap_count
    FROM prev_day
    GROUP BY customer_id
    HAVING COUNT(*) >= 3
)
SELECT
    customer_id,
    total_gap_count,
    long_gap_count,
    ROUND(long_gap_count / total_gap_count * 100, 2) AS long_gap_rate
FROM gap_count
ORDER BY long_gap_count / total_gap_count DESC,
         long_gap_count DESC,
         customer_id ASC
LIMIT 20;
