-- Day 24: final recorded SQL. Historical output and later checks are separate.

-- Exercise 1
USE f1_study;
SELECT d.team_name, COUNT(d.driver_number) AS driver_count,
       SUM(completed_laps) AS total_laps, SUM(points) AS total_points
FROM drivers d
JOIN race_results r
    ON r.driver_number = d.driver_number
   AND r.session_key = d.session_key
WHERE r.session_key = 11412
GROUP BY d.team_name
ORDER BY total_points DESC, d.team_name ASC;

-- Exercise 2
USE f1_study;
SELECT COUNT(driver_number) AS total_driver_count,
       COUNT(CASE WHEN points > 0 THEN 1 END) AS scoring_driver_count,
       ROUND(COUNT(CASE WHEN points > 0 THEN 1 END)
             / COUNT(driver_number) * 100, 2) AS scoring_rate
FROM race_results
WHERE session_key = 11412;

-- Exercise 3
USE f1_study;
WITH 2026_f1 AS (
    SELECT d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    GROUP BY driver_number, full_name
)
SELECT driver_number, full_name, race_count, total_points
FROM 2026_f1
WHERE total_points >= 100
ORDER BY total_points DESC, driver_number ASC;

-- Exercise 4
USE f1_study;
WITH 2026_f1 AS (
    SELECT d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    GROUP BY d.driver_number, d.full_name
)
SELECT RANK() OVER (ORDER BY total_points DESC) AS points_rank,
       driver_number, full_name, race_count, total_points
FROM 2026_f1
ORDER BY points_rank ASC, driver_number ASC;

-- Exercise 5
USE f1_study;
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    GROUP BY d.team_name, d.driver_number, d.full_name
)
SELECT team_name,
       RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
       driver_number, full_name, race_count, total_points
FROM 2026_f1
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;

-- Exercise 6
USE f1_study;
WITH corrected_results AS (
    SELECT
        CASE
            WHEN d.session_key = 11404
                 AND d.driver_number = 50
                 AND d.team_name IS NULL
            THEN 'Haas F1 Team'
            ELSE d.team_name
        END AS team_name,
        d.driver_number,
        d.full_name,
        r.points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
),
team_driver_totals AS (
    SELECT team_name, driver_number, full_name,
           COUNT(*) AS race_count, SUM(points) AS total_points
    FROM corrected_results
    GROUP BY team_name, driver_number, full_name
)
SELECT team_name,
       RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
       driver_number, full_name, race_count, total_points
FROM team_driver_totals
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
