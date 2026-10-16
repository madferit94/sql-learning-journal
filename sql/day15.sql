-- Historical final queries transcribed from the study journal. Not rerun for publication.

-- Exercise 1: Laps below 109 seconds
SELECT driver_number,
    COUNT(lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN lap_duration < 109 THEN 1 END) AS under_109_count
FROM laps
GROUP BY driver_number
HAVING timed_lap_count >= 40
ORDER BY under_109_count DESC, driver_number ASC;

-- Exercise 2: Share of laps below 109 seconds
SELECT driver_number,
    COUNT(lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN lap_duration < 109 THEN 1 END) AS under_109_count,
    ROUND(
        COUNT(CASE WHEN lap_duration < 109 THEN 1 END)
        / COUNT(lap_duration) * 100, 2
    ) AS under_109_rate
FROM laps
GROUP BY driver_number
HAVING timed_lap_count >= 40
ORDER BY under_109_rate DESC, driver_number ASC;

-- Exercise 3: Team lap-time statistics
SELECT d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration,
    ROUND(MIN(l.lap_duration), 2) AS fastest_lap_duration
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY d.team_name
HAVING timed_lap_count >= 90
ORDER BY avg_lap_duration ASC, d.team_name ASC;

-- Exercise 4: Count drivers meeting a lap threshold
SELECT COUNT(*) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS timed_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 35
) AS driver;

-- Exercise 5: Mean of driver means
SELECT ROUND(AVG(avg_lap_duration), 2) AS avg_driver_lap_duration
FROM (
    SELECT COUNT(lap_duration) AS timed_lap_duration,
        AVG(lap_duration) AS avg_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 40
) AS driver;
