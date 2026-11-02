-- Scoped MySQL 8.4.11 audit: 2026-11-02. See docs/audit.en.md.
-- Historical scope: 18 main races through Austin; exclude Mexico session 11404.

-- Final recorded queries; 2026 main races through Austin, no Sprint points.

-- Exercise 1
SELECT
    position AS race_position,
    d.driver_number,
    d.full_name,
    d.team_name,
    r.completed_laps,
    r.points
FROM drivers d
JOIN race_results r
    ON r.session_key = d.session_key
   AND r.driver_number = d.driver_number
WHERE r.session_key = 11396
  AND r.position IS NOT NULL
ORDER BY race_position ASC, driver_number ASC;

-- Exercise 2
SELECT
    d.team_name,
    COUNT(*) AS driver_count,
    SUM(completed_laps) AS total_laps,
    SUM(points) AS total_points
FROM drivers d
JOIN race_results r
    ON r.session_key = d.session_key
   AND r.driver_number = d.driver_number
WHERE r.session_key = 11396
GROUP BY d.team_name
ORDER BY total_points DESC, team_name ASC;

-- Exercise 3
WITH driver_totals AS (
    SELECT
        d.driver_number,
        d.full_name,
        COUNT(*) AS race_count,
        SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name
)
SELECT driver_number, full_name, race_count, total_points
FROM driver_totals
WHERE total_points >= 100
ORDER BY total_points DESC, driver_number ASC;

-- Exercise 4
WITH driver_totals AS (
    SELECT
        d.driver_number,
        d.full_name,
        COUNT(*) AS race_count,
        SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name
)
SELECT
    RANK() OVER (ORDER BY total_points DESC) points_rank,
    driver_number,
    full_name,
    race_count,
    total_points
FROM driver_totals
ORDER BY points_rank ASC, driver_number ASC;

-- Exercise 5
WITH team_driver_totals AS (
    SELECT
        d.team_name,
        d.driver_number,
        d.full_name,
        COUNT(*) AS race_count,
        SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
    GROUP BY d.team_name, d.driver_number, d.full_name
)
SELECT
    team_name,
    RANK() OVER (
        PARTITION BY team_name
        ORDER BY total_points DESC
    ) AS team_rank,
    driver_number,
    full_name,
    race_count,
    total_points
FROM team_driver_totals
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
