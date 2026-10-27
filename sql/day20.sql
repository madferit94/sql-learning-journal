-- Recorded final queries. Read the matching lesson and schema before running.

-- Exercise 1
SELECT
    d.driver_number,
    d.full_name,
    d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(lap_duration), 2) AS avg_lap_duration
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY d.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;

-- Exercise 2
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(lap_duration) AS timed_lap_count,
        ROUND(AVG(lap_duration), 2) AS avg_lap_duration
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY driver_number, full_name, team_name
)
SELECT
    driver_number,
    full_name,
    team_name,
    timed_lap_count,
    avg_lap_duration
FROM driver_stats
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;

-- Exercise 3
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(l.lap_duration) AS timed_lap_count
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name, d.team_name
)
SELECT COUNT(timed_lap_count) AS driver_count
FROM driver_stats
WHERE timed_lap_count >= 40;

-- Exercise 4
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(lap_duration) AS timed_lap_count,
        AVG(lap_duration) AS avg_lap_duration
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name, d.team_name
)
SELECT
    driver_number,
    full_name,
    team_name,
    timed_lap_count,
    ROUND(avg_lap_duration, 2) AS avg_lap_duration,
    RANK() OVER (
        ORDER BY avg_lap_duration ASC
    ) AS lap_rank
FROM driver_stats
WHERE timed_lap_count >= 40
ORDER BY lap_rank ASC, driver_number ASC;

-- Exercise 5
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(lap_duration) AS timed_lap_count,
        AVG(lap_duration) AS avg_lap_duration
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name, d.team_name
)
SELECT
    driver_number,
    full_name,
    team_name,
    timed_lap_count,
    ROUND(avg_lap_duration, 2) AS avg_lap_duration,
    RANK() OVER (
        PARTITION BY team_name
        ORDER BY avg_lap_duration ASC
    ) AS team_rank
FROM driver_stats
WHERE timed_lap_count >= 40
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
