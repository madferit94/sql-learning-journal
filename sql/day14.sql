-- Historical final queries transcribed from the study journal. Not rerun for publication.

-- Exercise 1: Driver lap-time statistics
SELECT driver_number, full_name,
    COUNT(lap_duration) AS timed_lap_count,
    ROUND(AVG(lap_duration), 2) AS avg_lap_duration
FROM lap_details
GROUP BY driver_number, full_name
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;

-- Exercise 2: Join driver and lap records
SELECT l.driver_number, d.full_name, d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;

-- Exercise 3: Laps below 110 seconds
SELECT l.driver_number, d.full_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END) AS under_110_count
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY under_110_count DESC, driver_number ASC;

-- Exercise 4: Team share of laps below 110 seconds
SELECT d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END) AS under_110_count,
    ROUND(
        COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END)
        / COUNT(l.lap_duration) * 100, 2
    ) AS under_110_rate
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY d.team_name
HAVING timed_lap_count >= 80
ORDER BY under_110_rate DESC, team_name ASC;

-- Exercise 5: Count qualifying drivers
SELECT COUNT(*) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS under_110_count
    FROM laps
    GROUP BY driver_number
    HAVING under_110_count >= 40
) AS qualifying_drivers;
