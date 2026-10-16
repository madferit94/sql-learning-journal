# Day 15 — Baku F1 independent practice and aggregate subqueries

[한국어](../ko/day15.md) · [Index](../../README.md)

Study date: 2026-10-13. Edited translation of every exercise, with historical SQL and source output excerpts; not rerun for publication.

Schema and row-grain details: [data notes](../../docs/data.en.md). Questions are custom practice exercises in a coding-platform format, not official Programmers or LeetCode problems.

## Exercise 1 — Laps below 109 seconds

**Question.** For drivers with at least 40 timed laps, return their timed count and count below 109 seconds. Include zeros; sort conditional count descending and number ascending.

**Learning point.** Transfer conditional COUNT to a changed threshold; NULL is not a timed lap.

**Authorship and evidence.** First final submission correct without query correction; 16 user-run rows.

### Final query recorded in the journal

```sql
SELECT driver_number,
    COUNT(lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN lap_duration < 109 THEN 1 END) AS under_109_count
FROM laps
GROUP BY driver_number
HAVING timed_lap_count >= 40
ORDER BY under_109_count DESC, driver_number ASC;
```

### Recorded output (source excerpt)

| driver_number | timed_lap_count | under_109_count |
| --- | --- | --- |
| 63 | 51 | 41 |
| 3 | 51 | 39 |
| 6 | 51 | 39 |
| 16 | 51 | 38 |
| 81 | 51 | 37 |
| 44 | 51 | 35 |
| 12 | 51 | 32 |
| 30 | 51 | 22 |
| 87 | 51 | 22 |
| 31 | 51 | 21 |
| 55 | 51 | 19 |
| 5 | 51 | 14 |
| 41 | 51 | 14 |
| 27 | 51 | 12 |
| 11 | 51 | 11 |
| 77 | 49 | 1 |

## Exercise 2 — Share of laps below 109 seconds

**Question.** For the same drivers, return counts and percentage below 109, rounded to two decimals. Sort percentage descending then number ascending.

**Learning point.** The denominator is all timed laps, not only laps below the threshold.

**Authorship and evidence.** Final submitted query accepted as correct. The learner clarified that an earlier pasted sort expression was an in-progress draft, not the final submission. 16 rows.

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| driver_number | timed_lap_count | under_109_count | under_109_rate |
| --- | --- | --- | --- |
| 63 | 51 | 41 | 80.39 |
| 3 | 51 | 39 | 76.47 |
| 6 | 51 | 39 | 76.47 |
| 16 | 51 | 38 | 74.51 |
| 81 | 51 | 37 | 72.55 |
| 44 | 51 | 35 | 68.63 |
| 12 | 51 | 32 | 62.75 |
| 30 | 51 | 22 | 43.14 |
| 87 | 51 | 22 | 43.14 |
| 31 | 51 | 21 | 41.18 |
| 55 | 51 | 19 | 37.25 |
| 5 | 51 | 14 | 27.45 |
| 41 | 51 | 14 | 27.45 |
| 27 | 51 | 12 | 23.53 |
| 11 | 51 | 11 | 21.57 |
| 77 | 49 | 1 | 2.04 |

## Exercise 3 — Team lap-time statistics

**Question.** Join laps and drivers. For teams with at least 90 timed laps, show count, mean and minimum duration; round mean/minimum to two decimals. Sort rounded mean then team name ascending.

**Learning point.** Team grain, composite join keys, COUNT, AVG and MIN were chosen correctly.

**Authorship and evidence.** Learner logic correct initially; help concerned two typos and unusual whitespace. Seven user-run rows.

### Earlier attempt (historical; may be invalid)

```sql
SELECT d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration,
    ROUND(MIN(l.lap_duration), 2) AS fastest_lap_duration
FROM drivers d
JOIN laps l ON l.session_key = d.session_key AND l.driver_number = d.driver_number
GROPU BY d.team_name
HAVING timed_lap_count >= 90
ORDER BY avg_lap_durationn ASC, team_name ASC;
```

### Final query recorded in the journal

```sql
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
```

### Recorded output (source excerpt)

| team_name | timed_lap_count | avg_lap_duration | fastest_lap_duration |
| --- | --- | --- | --- |
| Red Bull Racing | 102 | 115.45 | 104.99 |
| Mercedes | 102 | 115.49 | 104.92 |
| Ferrari | 102 | 115.70 | 105.78 |
| Haas F1 Team | 102 | 115.96 | 106.98 |
| Racing Bulls | 102 | 115.98 | 106.85 |
| Audi | 102 | 116.01 | 106.34 |
| Cadillac | 100 | 116.54 | 107.36 |

## Exercise 4 — Count drivers meeting a lap threshold

**Question.** Count drivers with at least 35 laps below 110 seconds. Return one row and zero if none qualify.

**Learning point.** A table alias cannot be used as a column in COUNT. COUNT(*) counts the already-grouped driver rows.

**Authorship and evidence.** Derived-table structure, CASE and HAVING written independently; outer COUNT(driver) corrected with feedback. User result: 11.

### Earlier attempt (historical; may be invalid)

```sql
SELECT COUNT(driver) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS timed_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 35
) AS driver;
```

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS timed_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 35
) AS driver;
```

### Recorded output (source excerpt)

| driver_count |
| --- |
| 11 |

## Exercise 5 — Mean of driver means

**Question.** For drivers with at least 40 timed laps, calculate each driver's mean, then average those means with equal weight per driver. Do not round intermediate values; round the final mean to two decimals.

**Learning point.** Missing inner GROUP BY produces a global lap mean. ROUND(value) still rounds to an integer; removing ROUND requires removing its extra parenthesis.

**Authorship and evidence.** AI helped with grouping, intermediate rounding and a remaining parenthesis. User-run values progressed from 115.78 to 115.94 to final 115.90.

### Earlier attempt (historical; may be invalid)

```sql
SELECT ROUND(AVG(avg_lap_duration), 2) AS avg_driver_lap_duration
FROM (
    SELECT COUNT(lap_duration) AS timed_lap_duration,
        ROUND(AVG(lap_duration), 2) AS avg_lap_duration
    FROM laps
    HAVING timed_lap_duration >= 40
) AS driver;
```

### Final query recorded in the journal

```sql
SELECT ROUND(AVG(avg_lap_duration), 2) AS avg_driver_lap_duration
FROM (
    SELECT COUNT(lap_duration) AS timed_lap_duration,
        AVG(lap_duration) AS avg_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 40
) AS driver;
```

### Recorded output (source excerpt)

| avg_driver_lap_duration |
| --- |
| 115.90 |

