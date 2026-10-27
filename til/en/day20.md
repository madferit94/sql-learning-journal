# Day 20 — F1 joins, CTEs and introductory window functions

[한국어](../ko/day20.md) · [Index](../../README.md)

These historical exercises use Baku session 11377 only. drivers has one row per session/driver, and laps one row per session/driver/lap. Join session_key and driver_number together. lap_duration is DECIMAL(12,3) seconds; NULL means no recorded time. Later expansion of the local database to 18 races means these original unfiltered queries require a Baku-only source or an explicit session filter when rerun; the recorded SQL is preserved, not silently rewritten.

## Tables and column types

drivers: session_key INT, driver_number INT, full_name VARCHAR(100), team_name VARCHAR(100). laps: session_key INT, driver_number INT, lap_number INT, lap_duration DECIMAL(12,3) seconds (nullable). Keys are session/driver and session/driver/lap respectively.

## Exercise 1 — Driver mean lap times

**Question and conditions.** Join drivers and laps, count recorded lap_duration values and average them per driver with name and team. Retain at least 40 recorded laps, including exactly 40. Exclude NULL durations from count/mean. Round the displayed mean to two decimals and sort that value ascending, then driver_number ascending. Return driver_number, full_name, team_name, timed_lap_count and avg_lap_duration.

**Row grain, example and interpretation.** One row is one eligible driver. Driver number alone happens to work for this single-session snapshot but is unsafe across multiple sessions. Use both join keys. Fictional example: 45 and 40 timed laps qualify; 39 does not.

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver\_number | full\_name | team\_name | timed\_lap\_count | avg\_lap\_duration |
| --- | --- | --- | --- | --- |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 |
| 16 | Charles LECLERC | Ferrari | 51 | 115.62 |
| 12 | Kimi ANTONELLI | Mercedes | 51 | 115.63 |
| 44 | Lewis HAMILTON | Ferrari | 51 | 115.78 |
| 31 | Esteban OCON | Haas F1 Team | 51 | 115.95 |
| 41 | Arvid LINDBLAD | Racing Bulls | 51 | 115.95 |
| 87 | Oliver BEARMAN | Haas F1 Team | 51 | 115.97 |
| 55 | Carlos SAINZ | Williams | 51 | 115.98 |
| 27 | Nico HULKENBERG | Audi | 51 | 116.00 |
| 5 | Gabriel BORTOLETO | Audi | 51 | 116.01 |
| 30 | Liam LAWSON | Racing Bulls | 51 | 116.01 |
| 81 | Oscar PIASTRI | McLaren | 51 | 116.06 |
| 11 | Sergio PEREZ | Cadillac | 51 | 116.16 |
| 77 | Valtteri BOTTAS | Cadillac | 49 | 116.94 |


Recorded execution: 16 rows in set (0.00 sec).

## Exercise 2 — CTE driver lap statistics

**Question and conditions.** Create driver_stats with the same driver-level count and mean, then apply the at-least-40 condition in the outer query. Return the same five columns and sort rounded mean ascending then driver number ascending. NULL durations do not count.

**Row grain, example and interpretation.** One CTE row is one driver. The recorded MySQL outer HAVING runs correctly; WHERE would express filtering an already calculated column more clearly. Rounding inside is acceptable here because the mean is only displayed, not averaged again or used for an unrounded ranking.

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver\_number | full\_name | team\_name | timed\_lap\_count | avg\_lap\_duration |
| --- | --- | --- | --- | --- |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 |


Recorded execution: 16 rows in set (0.02 sec).

## Exercise 3 — Count eligible drivers with a CTE

**Question and conditions.** Join drivers/laps on both keys, create driver_stats with one recorded-lap count per driver and count the rows meeting at least 40 in the outer query. Return one driver_count row, zero if none qualify. Exactly 40 qualifies and NULL lap times do not count.

**Row grain, example and interpretation.** The recorded COUNT(timed_lap_count) equals COUNT(*) because the inner COUNT produces non-NULL values. This counts driver rows, not raw laps. Actual result: 16.

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver\_count |
| --- |
| 16 |


Recorded execution: 1 row in set (0.02 sec).

## Exercise 4 — Overall mean-lap ranking

**Question and conditions.** Create driver_stats without rounding its mean. In the outer query retain at least 40 timed laps and use RANK ordered by the original mean ascending. Return driver_number, full_name, team_name, timed_lap_count, displayed two-decimal avg_lap_duration and lap_rank. Sort lap_rank then driver_number ascending.

**Row grain, example and interpretation.** Window ORDER BY computes rank; final ORDER BY controls display. The displayed mean can tie while the underlying means differ: LINDBLAD and OCON both display 115.95 but rank 7 and 8. Fictional exact ties at 109.10 can share rank 2 with the next at 4.

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver\_number | full\_name | team\_name | timed\_lap\_count | avg\_lap\_duration | lap\_rank |
| --- | --- | --- | --- | --- | --- |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 | 1 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 | 2 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 | 3 |
| 16 | Charles LECLERC | Ferrari | 51 | 115.62 | 4 |
| 12 | Kimi ANTONELLI | Mercedes | 51 | 115.63 | 5 |
| 44 | Lewis HAMILTON | Ferrari | 51 | 115.78 | 6 |
| 41 | Arvid LINDBLAD | Racing Bulls | 51 | 115.95 | 7 |
| 31 | Esteban OCON | Haas F1 Team | 51 | 115.95 | 8 |
| 87 | Oliver BEARMAN | Haas F1 Team | 51 | 115.97 | 9 |
| 55 | Carlos SAINZ | Williams | 51 | 115.98 | 10 |
| 27 | Nico HULKENBERG | Audi | 51 | 116.00 | 11 |
| 30 | Liam LAWSON | Racing Bulls | 51 | 116.01 | 12 |
| 5 | Gabriel BORTOLETO | Audi | 51 | 116.01 | 13 |
| 81 | Oscar PIASTRI | McLaren | 51 | 116.06 | 14 |
| 11 | Sergio PEREZ | Cadillac | 51 | 116.16 | 15 |
| 77 | Valtteri BOTTAS | Cadillac | 49 | 116.94 | 16 |


Recorded execution: 16 rows in set (0.01 sec).

## Exercise 5 — Within-team mean-lap ranking

**Question and conditions.** Use the same unrounded driver_stats and at-least-40 timed-lap condition. Rank by original mean ascending separately within each team using PARTITION BY team_name. Display the mean at two decimals and return team_rank alongside the other five columns. Sort team_name, team_rank, driver_number ascending.

**Row grain, example and interpretation.** One row is one eligible driver. McLaren and Williams each have one eligible driver here, so only rank 1 appears; that does not mean they fielded only one driver. These are within-team mean-time rankings among the selected drivers, not official race results.

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver\_number | full\_name | team\_name | timed\_lap\_count | avg\_lap\_duration | team\_rank |
| --- | --- | --- | --- | --- | --- |
| 27 | Nico HULKENBERG | Audi | 51 | 116.00 | 1 |
| 5 | Gabriel BORTOLETO | Audi | 51 | 116.01 | 2 |
| 11 | Sergio PEREZ | Cadillac | 51 | 116.16 | 1 |
| 77 | Valtteri BOTTAS | Cadillac | 49 | 116.94 | 2 |
| 16 | Charles LECLERC | Ferrari | 51 | 115.62 | 1 |
| 44 | Lewis HAMILTON | Ferrari | 51 | 115.78 | 2 |
| 31 | Esteban OCON | Haas F1 Team | 51 | 115.95 | 1 |
| 87 | Oliver BEARMAN | Haas F1 Team | 51 | 115.97 | 2 |
| 81 | Oscar PIASTRI | McLaren | 51 | 116.06 | 1 |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 | 1 |
| 12 | Kimi ANTONELLI | Mercedes | 51 | 115.63 | 2 |
| 41 | Arvid LINDBLAD | Racing Bulls | 51 | 115.95 | 1 |
| 30 | Liam LAWSON | Racing Bulls | 51 | 116.01 | 2 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 | 1 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 | 2 |
| 55 | Carlos SAINZ | Williams | 51 | 115.98 | 1 |


Recorded execution: 16 rows in set (0.06 sec).

## Key concepts and next practice

The 40-timed-lap threshold is an instructional selection rule intended to avoid comparing extremely short records directly with long ones. It is not an official F1 or statistically validated rule. Baku is normally 51 race laps; timed-record count need not equal officially completed laps. Tyres, pits, safety cars and traffic remain uncontrolled. Removing the cutoff changes eligibility, not the metric into an official classification.

Practice later without looking at the solution. This publication preserves recorded executions; it does not execute the exercise SQL or claim production experience.
