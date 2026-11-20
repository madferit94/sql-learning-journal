-- Day29: five F1 exercises.
USE f1_study;

-- Question 1
WITH f1_2026 AS (
    SELECT r.driver_number, s.session_key, s.date_start, r.points
    FROM race_results AS r
    JOIN sessions AS s ON s.session_key = r.session_key
    WHERE r.dns = 0
),
previous_point_driver AS (
    SELECT driver_number, session_key, date_start, points,
           LAG(points) OVER (
               PARTITION BY driver_number
               ORDER BY date_start ASC, session_key ASC
           ) AS previous_points
    FROM f1_2026
)
SELECT driver_number, session_key, date_start, points, previous_points,
       points - previous_points AS points_change
FROM previous_point_driver
ORDER BY driver_number ASC, date_start ASC, session_key ASC
LIMIT 20;

-- Question 2
WITH f1_2026 AS (
    SELECT r.driver_number, s.session_key, s.date_start, r.points
    FROM race_results AS r
    JOIN sessions AS s ON s.session_key = r.session_key
    WHERE r.dns = 0
),
previous_point_driver AS (
    SELECT driver_number, session_key, date_start, points,
           LAG(points) OVER (
               PARTITION BY driver_number
               ORDER BY date_start ASC, session_key ASC
           ) AS previous_points
    FROM f1_2026
)
SELECT driver_number, session_key, date_start, points, previous_points,
       points - previous_points AS points_change
FROM previous_point_driver
WHERE points > previous_points
ORDER BY points_change DESC, driver_number ASC, date_start ASC, session_key ASC
LIMIT 20;

-- Question 3
WITH f1_2026 AS (
    SELECT r.driver_number, s.session_key, s.date_start, r.points
    FROM race_results AS r
    JOIN sessions AS s ON s.session_key = r.session_key
    WHERE r.dns = 0
),
previous_point_driver AS (
    SELECT driver_number, session_key, date_start, points,
           LAG(points) OVER (
               PARTITION BY driver_number
               ORDER BY date_start ASC, session_key ASC
           ) AS previous_points
    FROM f1_2026
)
SELECT driver_number,
       COUNT(CASE WHEN points - previous_points > 0 THEN 1 END) AS points_increase_count
FROM previous_point_driver
GROUP BY driver_number
HAVING points_increase_count >= 1
ORDER BY points_increase_count DESC, driver_number ASC
LIMIT 20;

-- Question 4
WITH team_driver_stats AS (
    SELECT d.team_name, d.driver_number,
           COUNT(*) AS race_count,
           COUNT(CASE WHEN r.points > 0 THEN 1 END) AS scoring_race_count,
           SUM(r.points) AS total_points
    FROM drivers AS d
    JOIN race_results AS r
      ON r.session_key = d.session_key
     AND r.driver_number = d.driver_number
    WHERE r.dns = 0
      AND d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number
    HAVING COUNT(*) >= 5
),
team_ranked AS (
    SELECT team_name, driver_number, race_count, scoring_race_count, total_points,
           ROW_NUMBER() OVER (
               PARTITION BY team_name
               ORDER BY scoring_race_count / race_count DESC,
                        total_points DESC,
                        driver_number ASC
           ) AS selection_no
    FROM team_driver_stats
)
SELECT team_name, selection_no, driver_number, race_count, scoring_race_count,
       ROUND(scoring_race_count / race_count * 100, 2) AS scoring_rate,
       total_points
FROM team_ranked
WHERE selection_no <= 2
ORDER BY team_name ASC, selection_no ASC;

-- Question 5
WITH team_driver_stats AS (
    SELECT d.team_name, d.driver_number,
           COUNT(*) AS race_count,
           COUNT(CASE WHEN r.points > 0 THEN 1 END) AS scoring_race_count,
           SUM(r.points) AS total_points
    FROM drivers AS d
    JOIN race_results AS r
      ON r.session_key = d.session_key
     AND r.driver_number = d.driver_number
    WHERE r.dns = 0
      AND d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number
    HAVING COUNT(*) >= 5
),
team_ranked AS (
    SELECT team_name, driver_number, race_count, scoring_race_count, total_points,
           ROW_NUMBER() OVER (
               PARTITION BY team_name
               ORDER BY scoring_race_count / race_count DESC,
                        total_points DESC,
                        driver_number ASC
           ) AS selection_no
    FROM team_driver_stats
)
SELECT team_name,
       COUNT(*) AS selected_driver_count,
       SUM(race_count) AS total_race_count,
       SUM(scoring_race_count) AS total_scoring_race_count,
       ROUND(SUM(scoring_race_count) / SUM(race_count) * 100, 2) AS combined_scoring_rate
FROM team_ranked
WHERE selection_no <= 2
GROUP BY team_name
ORDER BY team_name ASC;
