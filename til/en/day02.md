# Day 02 — Aggregation and row filters

[한국어 원기록](../ko/day02.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 11

**Question.** Calculate average away goals by season from 2013/2014 onward and sort by season ascending.

**Learning point.** Earlier attempts used the wrong column name and placed a condition in GROUP BY. GROUP BY defines the output unit; WHERE selects eligible rows.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
season,
AVG(away_goals) AS (avg_away_goals)
FROM `Match`
GROUP BY season > '2013/2014'
ORDER BY avg_away_goals DESC
LIMIT 10;
```

### Final query recorded in the journal

```sql
SELECT
season,
AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2013/2014'
GROUP BY season
ORDER BY season ASC;
```

### Recorded output (source excerpt)

| `season` | `avg_away_goals` |
| --- | --- |
| 2013/2014 | 1.18799472295515 |
| 2014/2015 | 1.15548872180451 |
| 2015/2016 | 1.21076368009621 |

## Exercise 12

**Question.** Rank seasons by average total goals per match, descending.

**Learning point.** Add home and away goals within each match before taking AVG. The earlier attempt omitted GROUP BY.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
season,
AVG(home_team_goal + away_team_goal) AS avg_total_goals
FROM `Match`
WHERE season
ORDER BY avg_total_goals;
```

### Final query recorded in the journal

```sql
SELECT
season,
AVG(home_team_goal + away_team_goal) AS avg_total_goals
FROM `Match`
GROUP BY season
ORDER BY avg_total_goals DESC;
```

### Recorded output (source excerpt)

| `season` | `avg_total_goals` |
| --- | --- |
| 2012/2013 | 2.77269938650307 |
| 2013/2014 | 2.76682058047493 |
| 2015/2016 | 2.75466025255562 |
| 2011/2012 | 2.71645962732919 |
| 2010/2011 | 2.68374233128834 |
| 2014/2015 | 2.67578947368421 |
| 2009/2010 | 2.67244582043344 |
| 2008/2009 | 2.60733613950692 |

## Exercise 13

**Question.** Count matches with at least three home goals by season and sort counts descending.

**Learning point.** Filter on the original home_team_goal column, not an aggregate alias. Check exact column names.

### Earlier attempt (historical; may be invalid)

```sql
SELECT
season,
COUNT(*) AS high_scoring_home_matches
FROM `Match`
WHERE high_scoring_home_matchesl >= 3;
```

### Final query recorded in the journal

```sql
SELECT
season,
COUNT(*) AS high_scoring_home_matches
FROM `Match`
WHERE home_team_goal >= 3
GROUP BY season
ORDER BY high_scoring_home_matches DESC;
```

### Recorded output (source excerpt)

| `season` | `high_scoring_home_matches` |
| --- | --- |
| 2011/2012 | 703 |
| 2015/2016 | 685 |
| 2012/2013 | 673 |
| 2013/2014 | 664 |
| 2014/2015 | 663 |
| 2010/2011 | 656 |
| 2009/2010 | 655 |
| 2008/2009 | 645 |

## Exercise 14

**Question.** Count away wins by season and sort counts descending.

**Learning point.** An away win means away_team_goal > home_team_goal; count only those rows.

### Final query recorded in the journal

```sql
SELECT
season,
COUNT(*) AS away_win_matches
FROM `Match`
WHERE away_team_goal > home_team_goal
GROUP BY season
ORDER BY away_win_matches DESC;
```

### Recorded output (source excerpt)

| `season` | `away_win_matches` |
| --- | --- |
| 2015/2016 | 1012 |
| 2014/2015 | 981 |
| 2012/2013 | 963 |
| 2008/2009 | 929 |
| 2011/2012 | 904 |
| 2010/2011 | 901 |
| 2013/2014 | 892 |
| 2009/2010 | 884 |

## Exercise 15

**Question.** Count draws by season and sort counts descending.

**Learning point.** A draw means equal scores. AS makes aliases clearer even where it is optional.

### Final query recorded in the journal

```sql
SELECT
season,
COUNT(*) draw_matches
FROM `Match`
WHERE home_team_goal = away_team_goal
GROUP BY season
ORDER BY draw_matches DESC;
```

### Recorded output (source excerpt)

| `season` | `draw_matches` |
| --- | --- |
| 2015/2016 | 855 |
| 2012/2013 | 853 |
| 2014/2015 | 850 |
| 2010/2011 | 839 |
| 2008/2009 | 831 |
| 2011/2012 | 818 |
| 2009/2010 | 814 |
| 2013/2014 | 736 |

