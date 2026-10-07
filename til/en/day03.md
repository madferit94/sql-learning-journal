# Day 03 — WHERE versus HAVING

[한국어 원기록](../ko/day03.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 16

**Question.** Rank seasons from 2010/2011 onward by average home goals descending.

**Learning point.** Use >= to include 2010/2011 and sort by the requested metric, not by season.

### Earlier attempt (historical; may be invalid)

```sql
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
WHERE season > '2013/2014'
GROUP BY season
ORDER BY season;
```

### Final query recorded in the journal

```sql
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
ORDER BY avg_home_goals DESC;
```

### Recorded output (source excerpt)

| `season` | `avg_home_goals` |
| --- | --- |
| 2013/2014 | 1.57882585751979 |
| 2011/2012 | 1.57267080745342 |
| 2012/2013 | 1.55 |
| 2010/2011 | 1.54846625766871 |
| 2015/2016 | 1.54389657245941 |
| 2014/2015 | 1.5203007518797 |

## Exercise 17

**Question.** Show seasons with at least 3,250 matches, ordered by match count descending.

**Learning point.** GROUP BY creates season groups; HAVING filters their counts. Some historical attempt snippets contain damaged Markdown and are retained as attempts.

### Earlier attempt (historical; may be invalid)

```sql
SELECT season, COUNT(**) AS match_count*
*FROM `Match`*
*HAVING COUNT(**) >= 3250;
```

### Final query recorded in the journal

```sql
SELECT season, COUNT(*) AS match_count
FROM `Match`
GROUP BY season
HAVING COUNT(*) >= 3250
ORDER BY match_count DESC;
```

### Recorded output (source excerpt)

| `season` | `match_count` |
| --- | --- |
| 2015/2016 | 3326 |
| 2008/2009 | 3326 |
| 2014/2015 | 3325 |
| 2012/2013 | 3260 |
| 2010/2011 | 3260 |

## Exercise 18

**Question.** Show seasons from 2012/2013 onward with average away goals of at least 1.18, sorted by that average descending.

**Learning point.** WHERE filters seasons; HAVING filters the resulting aggregate.

### Earlier attempt (historical; may be invalid)

```sql
SELECT season, AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2012/2013'
HAVING avg_away_goals >= 1.18
ORDER BY avg_away_goals DESC;
```

### Final query recorded in the journal

```sql
SELECT season, AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2012/2013'
GROUP BY season
HAVING avg_away_goals >= 1.18
ORDER BY avg_away_goals DESC;
```

### Recorded output (source excerpt)

| `season` | `avg_away_goals` |
| --- | --- |
| 2012/2013 | 1.22269938650307 |
| 2015/2016 | 1.21076368009621 |
| 2013/2014 | 1.18799472295515 |

## Exercise 19

**Question.** Show seasons from 2011/2012 onward with at least 8,800 total goals, sorted by total goals descending.

**Learning point.** The recorded first attempt satisfied the requested structure.

### Final query recorded in the journal

```sql
SELECT season, SUM(home_team_goal + away_team_goal) AS total_goals
FROM `Match`
WHERE season >= '2011/2012'
GROUP BY season
HAVING total_goals >= 8800
ORDER BY total_goals DESC;
```

### Recorded output (source excerpt)

| `season` | `total_goals` |
| --- | --- |
| 2015/2016 | 9162 |
| 2012/2013 | 9039 |
| 2014/2015 | 8897 |

## Exercise 20

**Question.** For seasons from 2010/2011 onward, calculate match count, average home goals and total goals; retain counts of at least 3,250 and sort by total goals descending.

**Learning point.** Compute several metrics at the same season grain. Earlier attempts missed the aggregate filter or separated metrics unnecessarily.

### Earlier attempt (historical; may be invalid)

```sql
SELECT season, COUNT(*) AS match_count
FROM `Match`
GROUP BY season
HAVING match_count >= 3250
ORDER BY match_count DESC;
```

### Final query recorded in the journal

```sql
SELECT
    season,
    COUNT(*) AS match_count,
    AVG(home_team_goal) AS avg_home_goals,
    SUM(home_team_goal + away_team_goal) AS total_goals
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
HAVING match_count >= 3250
ORDER BY total_goals DESC;
```

### Recorded output (source excerpt)

| `season` | `match_count` | `avg_home_goals` | `total_goals` |
| --- | --- | --- | --- |
| 2015/2016 | 3326 | 1.54389657245941 | 9162 |
| 2012/2013 | 3260 | 1.55 | 9039 |
| 2014/2015 | 3325 | 1.5203007518797 | 8897 |
| 2010/2011 | 3260 | 1.54846625766871 | 8749 |

