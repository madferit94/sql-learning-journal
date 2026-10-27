# Day 21 — F1 Austin results, multi-race totals, CTEs and window functions

[한국어](../ko/day21.md) · [Index](../../README.md)

These five exercises use the local 2026 snapshot through Austin: 18 main races and 396 driver-result records. Sprints, practice, qualifying and cancelled sessions are excluded. Exercises 1–2 use Austin session 11396 only; Exercises 3–5 use every loaded main race. SQL and output tables reproduce the final recorded executions and are not rerun for this publication.

## Tables and row grain

drivers has one row per session/driver: session_key INT, driver_number INT, full_name VARCHAR(100), team_name VARCHAR(100). race_results has one row per session/driver: session_key INT, driver_number INT, position INT (nullable), completed_laps INT and points DECIMAL(8,2). Join both key columns. Points and lap counts are non-NULL in this snapshot. A driver can have different teams in different sessions.

The stored position is an official final position. A points-based RANK is a new exercise metric, not that position. No 40-lap threshold applies to these result/points questions. Main-race points alone and RANK tie handling do not reproduce the full official championship standings.

## Exercise 1 — Austin official race results

**Question and conditions.** Join drivers and race_results and return official position as race_position, driver number, name, team, completed laps and points for session 11396 only. Exclude NULL positions, but keep zero-point and low-lap results. Use the stored position rather than ranking points. Sort race_position then driver_number ascending.

**Row grain and interpretation.** One row is one classified driver result at Austin. AS renames an existing column; it does not aggregate or calculate a rank. A CTE name does not filter a session. Summing all races or ranking zero-point drivers cannot reproduce a single official classification.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| race_position | driver_number | full_name | team_name | completed_laps | points |
| --- | --- | --- | --- | --- | --- |
| 1 | 12 | Kimi ANTONELLI | Mercedes | 56 | 25.00 |
| 2 | 16 | Charles LECLERC | Ferrari | 56 | 18.00 |
| 3 | 3 | Max VERSTAPPEN | Red Bull Racing | 56 | 15.00 |
| 4 | 44 | Lewis HAMILTON | Ferrari | 56 | 12.00 |
| 5 | 1 | Lando NORRIS | McLaren | 56 | 10.00 |
| 6 | 6 | Isack HADJAR | Red Bull Racing | 56 | 8.00 |
| 7 | 81 | Oscar PIASTRI | McLaren | 56 | 6.00 |
| 8 | 63 | George RUSSELL | Mercedes | 56 | 4.00 |
| 9 | 30 | Liam LAWSON | Racing Bulls | 56 | 2.00 |
| 10 | 10 | Pierre GASLY | Alpine | 56 | 1.00 |
| 11 | 27 | Nico HULKENBERG | Audi | 56 | 0.00 |
| 12 | 41 | Arvid LINDBLAD | Racing Bulls | 55 | 0.00 |
| 13 | 5 | Gabriel BORTOLETO | Audi | 55 | 0.00 |
| 14 | 31 | Esteban OCON | Haas F1 Team | 55 | 0.00 |
| 15 | 18 | Lance STROLL | Aston Martin | 55 | 0.00 |
| 16 | 14 | Fernando ALONSO | Aston Martin | 55 | 0.00 |
| 17 | 23 | Alexander ALBON | Williams | 55 | 0.00 |
| 18 | 55 | Carlos SAINZ | Williams | 55 | 0.00 |
| 19 | 11 | Sergio PEREZ | Cadillac | 55 | 0.00 |

Recorded execution: 19 rows in set (0.09 sec).

## Exercise 2 — Austin team totals

**Question and conditions.** For session 11396, join the two tables and group by team. Return team_name, driver_count, total_laps and total_points. Include NULL-position results and zero-point teams, with no minimum laps or points. Sort total_points descending, then team_name ascending.

**Row grain and interpretation.** One row is one team. Count linked driver-result rows and sum laps and points. Unlike Exercise 1, do not exclude a result just because its official position is NULL.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| team_name | driver_count | total_laps | total_points |
| --- | --- | --- | --- |
| Ferrari | 2 | 112 | 30.00 |
| Mercedes | 2 | 112 | 29.00 |
| Red Bull Racing | 2 | 112 | 23.00 |
| McLaren | 2 | 112 | 16.00 |
| Racing Bulls | 2 | 111 | 2.00 |
| Alpine | 2 | 91 | 1.00 |
| Aston Martin | 2 | 110 | 0.00 |
| Audi | 2 | 111 | 0.00 |
| Cadillac | 2 | 103 | 0.00 |
| Haas F1 Team | 2 | 79 | 0.00 |
| Williams | 2 | 110 | 0.00 |

Recorded execution: 11 rows in set (0.10 sec).

## Exercise 3 — Driver totals across the loaded races

**Question and conditions.** Using all 18 loaded main races, create driver_totals with one row per driver, race_count and total_points. Combine records across team changes. Include zero-point and NULL-position results in counts. In the outer query keep totals of at least 100, including exactly 100. Sort points descending then driver number ascending.

**Row grain and interpretation.** One CTE row already represents one driver, so another outer GROUP BY is redundant. Filter the calculated total_points column with WHERE. The recorded MySQL HAVING alternative produced the same rows; moving to WHERE clarifies the outer query role rather than correcting the numeric result.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- |
| 12 | Kimi ANTONELLI | 18 | 334.00 |
| 3 | Max VERSTAPPEN | 18 | 216.00 |
| 44 | Lewis HAMILTON | 18 | 214.00 |
| 63 | George RUSSELL | 18 | 208.00 |
| 16 | Charles LECLERC | 18 | 199.00 |
| 1 | Lando NORRIS | 18 | 178.00 |
| 81 | Oscar PIASTRI | 18 | 123.00 |
| 6 | Isack HADJAR | 15 | 105.00 |

Recorded execution: 8 rows in set (0.00 sec).

## Exercise 4 — Overall main-race points ranking

**Question and conditions.** Use driver_totals for all 18 main races and rank all drivers by summed points descending with RANK. Remove the 100-point filter; retain zero-point and NULL-position records. Combine team changes. Rank only by points, giving ties the same rank with gaps afterward. Display points_rank then driver_number ascending.

**Row grain and interpretation.** One row is one driver. The actual output has three drivers tied on 7 points at rank 16, followed by rank 19, and three zero-point drivers tied at rank 21. Window ordering computes ranks; the final ORDER BY controls display.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| points_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- |
| 1 | 12 | Kimi ANTONELLI | 18 | 334.00 |
| 2 | 3 | Max VERSTAPPEN | 18 | 216.00 |
| 3 | 44 | Lewis HAMILTON | 18 | 214.00 |
| 4 | 63 | George RUSSELL | 18 | 208.00 |
| 5 | 16 | Charles LECLERC | 18 | 199.00 |
| 6 | 1 | Lando NORRIS | 18 | 178.00 |
| 7 | 81 | Oscar PIASTRI | 18 | 123.00 |
| 8 | 6 | Isack HADJAR | 15 | 105.00 |
| 9 | 30 | Liam LAWSON | 18 | 70.00 |
| 10 | 10 | Pierre GASLY | 18 | 40.00 |
| 11 | 41 | Arvid LINDBLAD | 18 | 37.00 |
| 12 | 43 | Franco COLAPINTO | 18 | 27.00 |
| 13 | 87 | Oliver BEARMAN | 18 | 19.00 |
| 14 | 27 | Nico HULKENBERG | 18 | 11.00 |
| 15 | 5 | Gabriel BORTOLETO | 18 | 10.00 |
| 16 | 14 | Fernando ALONSO | 18 | 7.00 |
| 16 | 31 | Esteban OCON | 18 | 7.00 |
| 16 | 55 | Carlos SAINZ | 18 | 7.00 |
| 19 | 23 | Alexander ALBON | 18 | 5.00 |
| 20 | 22 | Yuki TSUNODA | 3 | 1.00 |
| 21 | 11 | Sergio PEREZ | 18 | 0.00 |
| 21 | 18 | Lance STROLL | 18 | 0.00 |
| 21 | 77 | Valtteri BOTTAS | 18 | 0.00 |

Recorded execution: 23 rows in set (0.01 sec).

## Exercise 5 — Within-team main-race points ranking

**Question and conditions.** Using all 18 main races, create team_driver_totals grouped by team and driver. Keep team-change records separate and sum only points earned for that team. Include zero points and NULL positions, with no minimum count. Use RANK within each team by total_points descending only. Sort team_name, team_rank and driver_number ascending.

**Row grain and interpretation.** One row is a driver-team pair. LAWSON has 15 results/56 points for Racing Bulls and 3 results/14 points for Red Bull Racing, totaling the 70 points in Exercise 4. Both Cadillac drivers tie for team rank 1 on zero points. This is an exercise ranking, not an official championship order.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| team_name | team_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 18 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 18 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 18 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 18 | 0.00 |
| Audi | 1 | 27 | Nico HULKENBERG | 18 | 11.00 |
| Audi | 2 | 5 | Gabriel BORTOLETO | 18 | 10.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 18 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 18 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 18 | 214.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 18 | 199.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 18 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| McLaren | 1 | 1 | Lando NORRIS | 18 | 178.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 18 | 123.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 18 | 334.00 |
| Mercedes | 2 | 63 | George RUSSELL | 18 | 208.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 15 | 56.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 18 | 37.00 |
| Racing Bulls | 3 | 22 | Yuki TSUNODA | 3 | 1.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 18 | 216.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 15 | 105.00 |
| Red Bull Racing | 3 | 30 | Liam LAWSON | 3 | 14.00 |
| Williams | 1 | 55 | Carlos SAINZ | 18 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 18 | 5.00 |

Recorded execution: 24 rows in set (0.10 sec).

## Key concepts

Read existing result columns when the requested value is already stored. Aggregate when the output grain changes. A CTE that already contains one row per driver needs no additional outer GROUP BY. Overall driver totals combine team changes; within-team contributions separate driver-team pairs. Window ORDER BY assigns ranks, and the final ORDER BY sets display order.

## Next practice

- Rebuild the two result grains without the previous answer.
- Explain why the overall ranking has 23 drivers but the driver-team ranking has 24 rows.
- Distinguish stored official positions, aggregate points ranks and official championship tie-breaking.
