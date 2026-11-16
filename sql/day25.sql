-- Day 25: final recorded SQL. Historical output and later checks are separate.

-- Exercise 1
USE f1_study;
WITH f1_race AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.full_name, d.driver_number
)
SELECT team_name,
       RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
       driver_number, full_name, race_count, total_points
FROM f1_race
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;

-- Exercise 2
USE f1_study;
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number, d.full_name
),
2026_top2_rank AS (
    SELECT team_name,
           RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
           driver_number, full_name, race_count, total_points
    FROM 2026_f1
)
SELECT team_name, team_rank, driver_number, full_name, race_count, total_points
FROM 2026_top2_rank
WHERE team_rank <= 2
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;

-- Exercise 3
USE f1_study;
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number, d.full_name
),
f1_selection AS (
    SELECT team_name,
           ROW_NUMBER() OVER (
               PARTITION BY team_name
               ORDER BY total_points DESC, driver_number ASC
           ) AS selection_no,
           driver_number, full_name, race_count, total_points
    FROM 2026_f1
)
SELECT team_name, selection_no, driver_number, full_name, race_count, total_points
FROM f1_selection
WHERE selection_no <= 2
ORDER BY team_name ASC, selection_no ASC;

-- Exercise 4
USE finance;
WITH recent_transaction AS (
    SELECT customer_id, transaction_id, transaction_date, transaction_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY transaction_date DESC,
                        transaction_amount DESC,
                        transaction_id ASC
           ) AS rn
    FROM bank_transactions
)
SELECT customer_id, transaction_id, transaction_date, transaction_amount
FROM recent_transaction
WHERE rn <= 1
ORDER BY customer_id ASC;

-- Exercise 5
USE finance;
WITH recent_transaction AS (
    SELECT customer_id, transaction_id, transaction_date, transaction_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY transaction_date DESC,
                        transaction_amount DESC,
                        transaction_id ASC
           ) AS rn
    FROM bank_transactions
)
SELECT customer_id, transaction_id, transaction_date, transaction_amount
FROM recent_transaction
WHERE transaction_amount >= 5000 AND rn <= 1
ORDER BY transaction_amount DESC, customer_id ASC;
