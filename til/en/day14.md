# Day 14 — Baku F1 joins and conditional aggregation

[한국어](../ko/day14.md) · [Index](../../README.md)

Study date: 2026-10-12. Edited translation of every exercise, with historical SQL and source output excerpts; not rerun for publication.

Schema and row-grain details: [data notes](../../docs/data.en.md). Questions are custom practice exercises in a coding-platform format, not official Programmers or LeetCode problems.

## Exercise 1 — Driver lap-time statistics

**Question.** Using lap_details, return driver number/name, timed-lap count and mean lap duration for drivers with at least 40 timed laps. Round mean to two decimals; sort rounded mean then driver number ascending.

**Learning point.** The threshold refers to lap count, not average seconds. COUNT(lap_duration) and AVG both ignore NULL.

**Authorship and evidence.** AI-assisted correction of aggregate threshold, selected columns, sorting and typos; 16 user-run rows.

### Earlier attempt (historical; may be invalid)

```sql
SELECT driver_number, full_name, lap_number,
    ROUND(AVG(lap_duration), 2) AS avg_lap_duration
FROM lap_details
GROUP BY driver_number
HAVING avg_lap_duration >= 40
ORDER BY avg_lap_duration ASC, driver_number DESC;
```

### Final query recorded in the journal

```sql
SELECT driver_number, full_name,
    COUNT(lap_duration) AS timed_lap_count,
    ROUND(AVG(lap_duration), 2) AS avg_lap_duration
FROM lap_details
GROUP BY driver_number, full_name
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;
```

### Recorded output (source excerpt)

| driver_number | full_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- |
| 63 | George RUSSELL | 51 | 115.34 |
| 3 | Max VERSTAPPEN | 51 | 115.35 |
| 6 | Isack HADJAR | 51 | 115.55 |
| 16 | Charles LECLERC | 51 | 115.62 |
| 12 | Kimi ANTONELLI | 51 | 115.63 |
| 44 | Lewis HAMILTON | 51 | 115.78 |
| 31 | Esteban OCON | 51 | 115.95 |
| 41 | Arvid LINDBLAD | 51 | 115.95 |
| 87 | Oliver BEARMAN | 51 | 115.97 |
| 55 | Carlos SAINZ | 51 | 115.98 |
| 27 | Nico HULKENBERG | 51 | 116.00 |
| 5 | Gabriel BORTOLETO | 51 | 116.01 |
| 30 | Liam LAWSON | 51 | 116.01 |
| 81 | Oscar PIASTRI | 51 | 116.06 |
| 11 | Sergio PEREZ | 51 | 116.16 |
| 77 | Valtteri BOTTAS | 49 | 116.94 |

## Exercise 2 — Join driver and lap records

**Question.** Join laps and drivers to return driver number/name/team and timed count/rounded mean for at least 40 timed laps. Sort rounded mean and number ascending; do not use lap_details.

**Learning point.** Match both session_key and driver_number; matching only the session attaches other drivers' laps.

**Authorship and evidence.** Learner corrected the join and grouping after feedback; 16 user-run rows.

### Earlier attempt (historical; may be invalid)

```sql
SELECT l.driver_number, d.full_name, d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration
FROM drivers d
JOIN laps l ON l.session_key = d.session_key
GROUP BY d.driver_number
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;
```

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration |
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

## Exercise 3 — Laps below 110 seconds

**Question.** Join laps and drivers; for drivers with at least 40 timed laps, show total timed laps and the count below 110 seconds, including zero counts. Sort conditional count descending and number ascending.

**Learning point.** COUNT(comparison) counts both 0 and 1. Use a CASE that returns NULL for nonmatches; the comparison must be less than 110.

**Authorship and evidence.** AI supplied the conditional-count expression; learner corrected and executed it. 16 rows; no zero-count driver appeared in the actual result.

### Earlier attempt (historical; may be invalid)

```sql
SELECT l.driver_number, d.full_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    COUNT(l.lap_duration > 110) AS under_110_count
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY under_110_count DESC, driver_number ASC;
```

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver_number | full_name | timed_lap_count | under_110_count |
| --- | --- | --- | --- |
| 3 | Max VERSTAPPEN | 51 | 42 |
| 6 | Isack HADJAR | 51 | 42 |
| 63 | George RUSSELL | 51 | 42 |
| 81 | Oscar PIASTRI | 51 | 41 |
| 16 | Charles LECLERC | 51 | 40 |
| 44 | Lewis HAMILTON | 51 | 40 |
| 12 | Kimi ANTONELLI | 51 | 38 |
| 87 | Oliver BEARMAN | 51 | 38 |
| 41 | Arvid LINDBLAD | 51 | 36 |
| 30 | Liam LAWSON | 51 | 35 |
| 31 | Esteban OCON | 51 | 35 |
| 27 | Nico HULKENBERG | 51 | 33 |
| 5 | Gabriel BORTOLETO | 51 | 31 |
| 55 | Carlos SAINZ | 51 | 28 |
| 11 | Sergio PEREZ | 51 | 26 |
| 77 | Valtteri BOTTAS | 49 | 9 |

## Exercise 4 — Team share of laps below 110 seconds

**Question.** Join laps and drivers; for teams with at least 80 timed laps, return timed count, count below 110 and the percentage rounded to two decimals. Include zeros; sort percentage descending then team name ascending.

**Learning point.** Group by team, not driver; repeat aggregate expressions rather than referencing sibling SELECT aliases.

**Authorship and evidence.** AI guidance on grain, aliases and formula plus typo cleanup. Nine user-run rows; Red Bull 84/102 = 82.35%.

### Earlier attempt (historical; may be invalid)

```sql
SELECT d.team_name,
    COUNT(l.lap_durtion) AS timed_lap_count,
    COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END) AS under_110_count,
    ROUND(under_110_count / timed_lap_count * 100, 2) AS under_110_rate
FORM drivers d
JOIN laps l ON l.session_key = d.session_key AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 80
ORDER BY under_110_rate DESC, team_name ASC;
```

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| team_name | timed_lap_count | under_110_count | under_110_rate |
| --- | --- | --- | --- |
| Red Bull Racing | 102 | 84 | 82.35 |
| Ferrari | 102 | 80 | 78.43 |
| Mercedes | 102 | 80 | 78.43 |
| McLaren | 86 | 67 | 77.91 |
| Haas F1 Team | 102 | 73 | 71.57 |
| Racing Bulls | 102 | 71 | 69.61 |
| Audi | 102 | 64 | 62.75 |
| Williams | 80 | 50 | 62.50 |
| Cadillac | 100 | 35 | 35.00 |

## Exercise 5 — Count qualifying drivers

**Question.** Count drivers with at least 40 laps below 110 seconds. Exclude NULL from that conditional count and return zero if none qualify.

**Learning point.** Build one row per qualifying driver inside the derived table, then count those rows.

**Authorship and evidence.** AI supplied the structure and final correction after nested-SELECT errors. User result: 6. Later practice demonstrated a rewrite but not a fresh execution of the whole rewritten query.

### Earlier attempt (historical; may be invalid)

```sql
SELECT COUNT(under_110_count) AS driver_count
FROM laps (SELECT COUNT(CASE WHEN lap_duration < 110 THEN 1 ELSE 0 END)
FROM laps
GROUP BY driver_number
WHERE lap_duration NOT IN ('NULL')
) AS under_110_count
GROUP BY driver_number
HAVING under_110_count >= 40;
```

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS under_110_count
    FROM laps
    GROUP BY driver_number
    HAVING under_110_count >= 40
) AS qualifying_drivers;
```

### Recorded output (source excerpt)

| driver_count |
| --- |
| 6 |

