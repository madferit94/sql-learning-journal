# Day 24 — F1 aggregation, CTEs, ranks and a scoped team correction

[한국어](../ko/day24.md) · [Index](../../README.md)

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

```sql
USE f1_study;
```

## Exercise 1 — Brazil team totals

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Join both tables on both keys; use session 11412 only. Include all result registrations. Return team_name, driver_count, total_laps and total_points. One row per team. Sort total_points DESC, team_name ASC. Fictional example: two registered drivers with 71 and 30 laps total 101 laps.

### Final query recorded in the journal

```sql
SELECT d.team_name, COUNT(d.driver_number) AS driver_count,
       SUM(completed_laps) AS total_laps, SUM(points) AS total_points
FROM drivers d
JOIN race_results r
    ON r.driver_number = d.driver_number
   AND r.session_key = d.session_key
WHERE r.session_key = 11412
GROUP BY d.team_name
ORDER BY total_points DESC, d.team_name ASC;
```

### Recorded output (user terminal)

| team_name | driver_count | total_laps | total_points |
| --- | --- | --- | --- |
| McLaren | 2 | 142 | 33.00 |
| Red Bull Racing | 2 | 142 | 33.00 |
| Mercedes | 2 | 142 | 22.00 |
| Ferrari | 2 | 141 | 6.00 |
| Racing Bulls | 2 | 141 | 6.00 |
| Audi | 2 | 140 | 1.00 |
| Alpine | 2 | 140 | 0.00 |
| Aston Martin | 2 | 100 | 0.00 |
| Cadillac | 2 | 69 | 0.00 |
| Haas F1 Team | 2 | 139 | 0.00 |
| Williams | 2 | 139 | 0.00 |

Recorded rows/runtime: 11 rows / 0.01 sec.

### Reasoning and interpretation

Both join keys prevent multiplication. COUNT(driver_number) equals COUNT(*) here because the identifier is non-NULL. A registration can be counted even if DNS. McLaren and Red Bull tie at 33, so team name determines display order.

## Exercise 2 — Brazil scoring-driver percentage

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Use race_results only, session 11412. Scoring means points > 0. Keep every registered driver in the denominator, including zero-point/DNS/DNF rows. Return total_driver_count, scoring_driver_count, scoring_rate = scoring/total*100, rounded to two decimals; one summary row, no final sort. Fictional example: 8 of 20 gives 40.00%.

### Final query recorded in the journal

```sql
SELECT COUNT(driver_number) AS total_driver_count,
       COUNT(CASE WHEN points > 0 THEN 1 END) AS scoring_driver_count,
       ROUND(COUNT(CASE WHEN points > 0 THEN 1 END)
             / COUNT(driver_number) * 100, 2) AS scoring_rate
FROM race_results
WHERE session_key = 11412;
```

### Recorded output (user terminal)

| total_driver_count | scoring_driver_count | scoring_rate |
| --- | --- | --- |
| 22 | 10 | 45.45 |

Recorded rows/runtime: 1 rows / 0.00 sec.

### Reasoning and interpretation

The full denominator remains 22 and conditional COUNT counts the 10 scoring drivers: 45.45%. Filtering points > 0 before aggregation would discard the intended denominator.

## Exercise 3 — CTE: drivers with at least 100 main-race points

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Use a CTE and all 20 main races through Brazil. Join both keys and group by driver_number, full_name; combine team changes. Return driver_number, full_name, race_count and total_points for totals >= 100. Sort total_points DESC, driver_number ASC. One row per qualifying driver. Fictional totals 100 and 99: only 100 qualifies.

### Final query recorded in the journal

```sql
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
```

### Recorded output (user terminal)

| driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- |
| 12 | Kimi ANTONELLI | 20 | 359.00 |
| 3 | Max VERSTAPPEN | 20 | 259.00 |
| 44 | Lewis HAMILTON | 20 | 234.00 |
| 63 | George RUSSELL | 20 | 228.00 |
| 16 | Charles LECLERC | 20 | 215.00 |
| 1 | Lando NORRIS | 20 | 213.00 |
| 81 | Oscar PIASTRI | 20 | 131.00 |
| 6 | Isack HADJAR | 17 | 122.00 |

Recorded rows/runtime: 8 rows / 0.13 sec.

### Reasoning and interpretation

The final query followed self-correction. Intermediate queries/error messages were not supplied and are not reconstructed. The CTE already has one row per driver; outer WHERE filters stored totals without another GROUP BY.

## Exercise 4 — Overall driver points ranks

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Use a CTE and RANK across all drivers over all 20 main races. Aggregate by driver_number/full_name regardless of team; include zero-point registrations with no 100-point filter. Return points_rank, driver_number, full_name, race_count, total_points. Equal points tie and skip the next rank. Sort points_rank ASC, driver_number ASC. Fictional points 180/150/150/100 give ranks 1/2/2/4.

### Final query recorded in the journal

```sql
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
```

### Recorded output (user terminal)

| points_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- |
| 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| 2 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| 3 | 44 | Lewis HAMILTON | 20 | 234.00 |
| 4 | 63 | George RUSSELL | 20 | 228.00 |
| 5 | 16 | Charles LECLERC | 20 | 215.00 |
| 6 | 1 | Lando NORRIS | 20 | 213.00 |
| 7 | 81 | Oscar PIASTRI | 20 | 131.00 |
| 8 | 6 | Isack HADJAR | 17 | 122.00 |
| 9 | 30 | Liam LAWSON | 20 | 82.00 |
| 10 | 10 | Pierre GASLY | 20 | 40.00 |
| 11 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| 12 | 43 | Franco COLAPINTO | 20 | 27.00 |
| 13 | 87 | Oliver BEARMAN | 20 | 19.00 |
| 14 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| 15 | 27 | Nico HULKENBERG | 20 | 12.00 |
| 16 | 14 | Fernando ALONSO | 20 | 7.00 |
| 16 | 31 | Esteban OCON | 18 | 7.00 |
| 16 | 55 | Carlos SAINZ | 20 | 7.00 |
| 19 | 23 | Alexander ALBON | 20 | 5.00 |
| 20 | 22 | Yuki TSUNODA | 3 | 1.00 |
| 20 | 50 | Ryo HIRAKAWA | 1 | 1.00 |
| 22 | 11 | Sergio PEREZ | 20 | 0.00 |
| 22 | 18 | Lance STROLL | 20 | 0.00 |
| 22 | 51 | Rafael CAMARA | 1 | 0.00 |
| 22 | 77 | Valtteri BOTTAS | 20 | 0.00 |

Recorded rows/runtime: 25 rows / 0.17 sec.

### Reasoning and interpretation

Three drivers with seven points share rank 16; the next is rank 19. Window ordering computes ranks, final ordering displays rows. Driver number is only a display tie-breaker.

## Exercise 5 — Within-team ranks using original team values

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Use a CTE and within-team RANK over all 20 main races. Group by team_name, driver_number, full_name; split team changes. Retain NULL team values and zero-point/DNS/DNF records. Return team_name, team_rank, driver_number, full_name, race_count, total_points. Sort team_name ASC, team_rank ASC, driver_number ASC. One row per team-driver pair. Fictional driver with 90 points for A and 30 for B has two rows.

### Final query recorded in the journal

```sql
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
```

### Recorded output (user terminal)

| team_name | team_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| NULL | 1 | 50 | Ryo HIRAKAWA | 1 | 1.00 |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| Haas F1 Team | 3 | 51 | Rafael CAMARA | 1 | 0.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Racing Bulls | 3 | 22 | Yuki TSUNODA | 3 | 1.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Red Bull Racing | 3 | 30 | Liam LAWSON | 3 | 14.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

Recorded rows/runtime: 26 rows / 0.11 sec.

### Reasoning and interpretation

Ryo Hirakawa appears in a NULL team group. The cached official Mexico result identifies driver 50 as Haas F1 Team, tenth, one point. The query is correct for original data; a NULL-group rank is not an actual team standing. Official source: https://www.formula1.com/en/results/2026/races/1298/mexico/race-result . Lawson remains split by team.

## Exercise 6 — Within-team ranks after a scoped team correction

### Table and row grain

drivers: one row per session and driver; race_results: one result per session and driver. Both use (session_key, driver_number), INT NOT NULL, as the composite key. drivers.full_name and team_name are VARCHAR(100), nullable. race_results.points is DECIMAL(8,2), completed_laps INT, status VARCHAR(20). The loaded result points/laps are non-NULL. Points exclude Sprints; ranks are not official championship standings. Count result registrations, including DNS/DNF/zero-point entries, not actual starts.

### Question and conditions

Follow-up example execution: correct only session 11404, driver 50, where team_name IS NULL to Haas F1 Team. Preserve all other values and the source DB; apply the correction before team aggregation and ranking. All other scope, tie and sort rules match Exercise 5. Return team_name, team_rank, driver_number, full_name, race_count, total_points. Fictional analogy: a verified missing team for one registration does not justify changing every missing team.

### Final query recorded in the journal

```sql
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
```

### Recorded output (user terminal)

| team_name | team_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| Haas F1 Team | 3 | 50 | Ryo HIRAKAWA | 1 | 1.00 |
| Haas F1 Team | 4 | 51 | Rafael CAMARA | 1 | 0.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Racing Bulls | 3 | 22 | Yuki TSUNODA | 3 | 1.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Red Bull Racing | 3 | 30 | Liam LAWSON | 3 | 14.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

Recorded rows/runtime: 26 rows / 0.10 sec.

### Reasoning and interpretation

This is execution of a supplied follow-up example, separate from independent exercise solutions. Correct team first, aggregate second, rank third. Hirakawa becomes Haas rank 3 with one point; Camara becomes rank 4 with zero. There are still 26 rows. No UPDATE was performed. IFNULL/COALESCE provide fallback values; a scoped CASE needs verified evidence, rather than assigning every missing team to Haas.
