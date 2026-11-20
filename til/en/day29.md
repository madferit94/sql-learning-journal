# Day 29 — F1 previous-start points and team scoring rates

[한국어](../ko/day29.md) · [Index](../../README.md) · [SQL](../../sql/day29.sql)

MySQL 8.4 / f1_study. The loaded data contains 20 main races from 2026 and 440 result rows, including eight non-starts. The exercises use the 432 starts. The current snapshot already restricts sessions to 2026 main races; filter sessions explicitly if sprint or other sessions are added.

| Table | One row represents | Columns used |
| --- | --- | --- |
| sessions | One race session | session_key (INT, unique), year (INT), session_name (VARCHAR(40), Race means main race), date_start (VARCHAR(40), UTC start time) |
| race_results | One driver’s result in one race | session_key (INT), driver_number (INT), points (DECIMAL(8,2)), dns (BOOLEAN, 1 means did not start) |
| drivers | One registered driver in one session | session_key (INT), driver_number (INT), team_name (VARCHAR(100), team in that race, NULL if missing) |

Join sessions to race_results by session_key, and drivers to race_results by both session_key and driver_number.

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

```sql
USE f1_study;
```

## Exercise 1 — Compare points with the previous start

For each main-race start, return the current points, that driver’s previous-start points, and the difference. Exclude non-starts and keep zero-point starts. Both comparison columns are NULL on the first start. Sort by driver number, start time, and session ID ascending, then return 20 rows. Hypothetical example: 10 points → missed race → 18 points gives +8.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| driver_number | session_key | date_start | points | previous_points | points_change |
| --- | --- | --- | --- | --- | --- |
| 1 | 11234 | 2026-03-08T04:00:00+00:00 | 10.00 | NULL | NULL |
| 1 | 11253 | 2026-03-29T05:00:00+00:00 | 10.00 | 10.00 | 0.00 |
| 1 | 11280 | 2026-05-03T17:00:00+00:00 | 18.00 | 10.00 | 8.00 |
| 1 | 11291 | 2026-05-24T20:00:00+00:00 | 0.00 | 18.00 | -18.00 |
| 1 | 11299 | 2026-06-07T13:00:00+00:00 | 0.00 | 0.00 | 0.00 |
| 1 | 11307 | 2026-06-14T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 1 | 11315 | 2026-06-28T13:00:00+00:00 | 6.00 | 15.00 | -9.00 |
| 1 | 11326 | 2026-07-05T14:00:00+00:00 | 12.00 | 6.00 | 6.00 |
| 1 | 11334 | 2026-07-19T13:00:00+00:00 | 6.00 | 12.00 | -6.00 |
| 1 | 11342 | 2026-07-26T13:00:00+00:00 | 25.00 | 6.00 | 19.00 |
| 1 | 11353 | 2026-08-23T13:00:00+00:00 | 25.00 | 25.00 | 0.00 |
| 1 | 11361 | 2026-09-06T13:00:00+00:00 | 12.00 | 25.00 | -13.00 |
| 1 | 11369 | 2026-09-13T13:00:00+00:00 | 15.00 | 12.00 | 3.00 |
| 1 | 11377 | 2026-09-26T11:00:00+00:00 | 0.00 | 15.00 | -15.00 |
| 1 | 11731 | 2026-10-04T07:00:00+00:00 | 2.00 | 0.00 | 2.00 |
| 1 | 11388 | 2026-10-11T12:00:00+00:00 | 12.00 | 2.00 | 10.00 |
| 1 | 11396 | 2026-10-25T20:00:00+00:00 | 10.00 | 12.00 | -2.00 |
| 1 | 11404 | 2026-11-01T20:00:00+00:00 | 10.00 | 10.00 | 0.00 |
| 1 | 11412 | 2026-11-08T17:00:00+00:00 | 25.00 | 10.00 | 15.00 |
| 3 | 11234 | 2026-03-08T04:00:00+00:00 | 8.00 | NULL | NULL |

Find the previous start in chronological order. The final chronological sort cannot repair the initial LAG ordered by points. Subtract the already computed previous value from the current value. Driver 1 skipped 11245, comparing 11253 with 11234.

## Exercise 2 — Find races with improved points

Keep only starts with higher points than the previous start, one row per driver and race. Exclude first starts, ties and decreases. Compare all starts, sort by change descending followed by driver number, start time and session ID ascending, then show 20 rows. Hypothetical example: include 0 → 8 and exclude 8 → 8.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| driver_number | session_key | date_start | points | previous_points | points_change |
| --- | --- | --- | --- | --- | --- |
| 12 | 11334 | 2026-07-19T13:00:00+00:00 | 25.00 | 0.00 | 25.00 |
| 16 | 11326 | 2026-07-05T14:00:00+00:00 | 25.00 | 4.00 | 21.00 |
| 1 | 11342 | 2026-07-26T13:00:00+00:00 | 25.00 | 6.00 | 19.00 |
| 63 | 11307 | 2026-06-14T13:00:00+00:00 | 18.00 | 0.00 | 18.00 |
| 1 | 11307 | 2026-06-14T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 1 | 11412 | 2026-11-08T17:00:00+00:00 | 25.00 | 10.00 | 15.00 |
| 3 | 11334 | 2026-07-19T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 3 | 11361 | 2026-09-06T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 12 | 11315 | 2026-06-28T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 63 | 11377 | 2026-09-26T11:00:00+00:00 | 25.00 | 10.00 | 15.00 |
| 6 | 11412 | 2026-11-08T17:00:00+00:00 | 15.00 | 2.00 | 13.00 |
| 3 | 11307 | 2026-06-14T13:00:00+00:00 | 12.00 | 0.00 | 12.00 |
| 16 | 11369 | 2026-09-13T13:00:00+00:00 | 12.00 | 0.00 | 12.00 |
| 81 | 11299 | 2026-06-07T13:00:00+00:00 | 12.00 | 0.00 | 12.00 |
| 1 | 11388 | 2026-10-11T12:00:00+00:00 | 12.00 | 2.00 | 10.00 |
| 3 | 11404 | 2026-11-01T20:00:00+00:00 | 25.00 | 15.00 | 10.00 |
| 6 | 11291 | 2026-05-24T20:00:00+00:00 | 10.00 | 0.00 | 10.00 |
| 12 | 11396 | 2026-10-25T20:00:00+00:00 | 25.00 | 15.00 | 10.00 |
| 44 | 11291 | 2026-05-24T20:00:00+00:00 | 18.00 | 8.00 | 10.00 |
| 81 | 11334 | 2026-07-19T13:00:00+00:00 | 10.00 | 0.00 | 10.00 |

The original top 20 was unchanged because the 20th result already had a +10-point change. Sorting alone does not exclude non-increases; filter for strictly higher points after computing the previous value.

## Exercise 3 — Count improved races by driver

Across all main-race starts, show one row per driver with the number of increases over their previous start. Exclude drivers with no increases. Sort by count descending and driver number ascending, then show 20 rows. Hypothetical example: 0 → 8 → 8 → 10 has two increases.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| driver_number | points_increase_count |
| --- | --- |
| 3 | 11 |
| 63 | 10 |
| 30 | 9 |
| 44 | 9 |
| 1 | 8 |
| 81 | 8 |
| 6 | 7 |
| 10 | 7 |
| 12 | 7 |
| 43 | 7 |
| 16 | 6 |
| 27 | 5 |
| 41 | 4 |
| 14 | 3 |
| 31 | 3 |
| 55 | 3 |
| 87 | 3 |
| 5 | 2 |
| 23 | 2 |
| 22 | 1 |

Compute the previous value on start rows before grouping by driver. The conditional count excludes the first start and ties. HAVING removes drivers with a zero count after aggregation.

## Exercise 4 — Top two drivers by scoring rate within each team

After excluding non-starts and missing teams, select at most two drivers per team among drivers with at least five starts for that team. Count team stints separately. Scoring rate is the share of starts with points greater than zero. Rank by unrounded rate descending, total points descending, and driver number ascending. Display rates to two decimals, sorted by team and selection number. Hypothetical example: five scoring starts out of five outrank eight out of ten.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| team_name | selection_no | driver_number | race_count | scoring_race_count | scoring_rate | total_points |
| --- | --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | 20 | 10 | 50.00 | 40.00 |
| Alpine | 2 | 43 | 20 | 8 | 40.00 | 27.00 |
| Aston Martin | 1 | 14 | 20 | 3 | 15.00 | 7.00 |
| Aston Martin | 2 | 18 | 20 | 0 | 0.00 | 0.00 |
| Audi | 1 | 27 | 19 | 5 | 26.32 | 12.00 |
| Audi | 2 | 5 | 19 | 4 | 21.05 | 14.00 |
| Cadillac | 1 | 11 | 20 | 0 | 0.00 | 0.00 |
| Cadillac | 2 | 77 | 19 | 0 | 0.00 | 0.00 |
| Ferrari | 1 | 44 | 20 | 19 | 95.00 | 234.00 |
| Ferrari | 2 | 16 | 20 | 17 | 85.00 | 215.00 |
| Haas F1 Team | 1 | 87 | 20 | 4 | 20.00 | 19.00 |
| Haas F1 Team | 2 | 31 | 18 | 3 | 16.67 | 7.00 |
| McLaren | 1 | 1 | 19 | 16 | 84.21 | 213.00 |
| McLaren | 2 | 81 | 18 | 13 | 72.22 | 131.00 |
| Mercedes | 1 | 12 | 20 | 18 | 90.00 | 359.00 |
| Mercedes | 2 | 63 | 20 | 16 | 80.00 | 228.00 |
| Racing Bulls | 1 | 30 | 17 | 13 | 76.47 | 68.00 |
| Racing Bulls | 2 | 41 | 19 | 11 | 57.89 | 37.00 |
| Red Bull Racing | 1 | 6 | 17 | 14 | 82.35 | 122.00 |
| Red Bull Racing | 2 | 3 | 20 | 16 | 80.00 | 259.00 |
| Williams | 1 | 55 | 20 | 4 | 20.00 | 7.00 |
| Williams | 2 | 23 | 19 | 2 | 10.53 | 5.00 |

**Why require five starts?** Scoring in a single start gives 100%, so a very small sample can lead the ranking. Five starts is the exercise’s eligibility rule, not an F1 regulation or statistical guarantee. Apply HAVING COUNT(*) >= 5 after grouping by team and driver. Exactly five qualifies, starts for another team do not count, and zero-point starts remain in the denominator.

## Exercise 5 — Combined scoring rate of selected drivers

Use the same selection rules as Question 4. For each team, divide the selected drivers’ combined scoring starts by their combined starts. Count two driver starts when both started the same race. Retain teams with only one selection. Display two decimals and sort by team name ascending. Hypothetical example: combining 8/10 and 3/5 gives 11/15 = 73.33%, not the 70% average of the two individual rates.

### Final query recorded in the journal

```sql
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
```

### Recorded output

| team_name | selected_driver_count | total_race_count | total_scoring_race_count | combined_scoring_rate |
| --- | --- | --- | --- | --- |
| Alpine | 2 | 40 | 18 | 45.00 |
| Aston Martin | 2 | 40 | 3 | 7.50 |
| Audi | 2 | 38 | 9 | 23.68 |
| Cadillac | 2 | 39 | 0 | 0.00 |
| Ferrari | 2 | 40 | 36 | 90.00 |
| Haas F1 Team | 2 | 38 | 7 | 18.42 |
| McLaren | 2 | 37 | 29 | 78.38 |
| Mercedes | 2 | 40 | 34 | 85.00 |
| Racing Bulls | 2 | 36 | 24 | 66.67 |
| Red Bull Racing | 2 | 37 | 30 | 81.08 |
| Williams | 2 | 39 | 6 | 15.38 |

**What changes from Question 4?** Keep the first two CTEs and the top-two filter. Question 4’s final SELECT lists individual driver rows. Question 5 adds GROUP BY team_name, uses COUNT(*) for selected drivers, SUM(race_count) for starts, and SUM(scoring_race_count) for scoring starts. The final display sorts by team name only. Red Bull Racing returned 30 scoring starts out of 37, or 81.08%.
