# Day 01 — Basic selection, filtering and aggregation

[한국어 원기록](../ko/day01.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Return 10 matches from the 2015/2016 season, showing season, date and both teams' goals.

**Learning point.** Start with the table and required columns, then filter rows. LIMIT without ORDER BY does not guarantee which ten rows appear.

### Final query recorded in the journal

```sql
SELECT season, date, home_team_goal, away_team_goal
FROM `Match`
WHERE season = '2015/2016'
LIMIT 10;
```

### Recorded output (source excerpt)

| season | date | home_team_goal | away_team_goal |
| --- | --- | --- | --- |
| 2015/2016 | 2015-07-24 00:00:00 | 2 | 1 |
| 2015/2016 | 2015-07-25 00:00:00 | 2 | 1 |
| 2015/2016 | 2015-07-25 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-07-25 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-07-25 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-07-26 00:00:00 | 1 | 1 |
| 2015/2016 | 2015-07-26 00:00:00 | 3 | 2 |
| 2015/2016 | 2015-07-26 00:00:00 | 2 | 1 |
| 2015/2016 | 2015-10-04 00:00:00 | 1 | 1 |
| 2015/2016 | 2015-10-04 00:00:00 | 4 | 1 |

## Exercise 2

**Question.** Return 10 matches with at least three home goals.

**Learning point.** Use >= to include the boundary value of three.

### Final query recorded in the journal

```sql
SELECT date, home_team_goal, away_team_goal
FROM `Match`
WHERE home_team_goal >= 3
LIMIT 10;
```

### Recorded output (source excerpt)

| date | home_team_goal | away_team_goal |
| --- | --- | --- |
| 2008-08-17 00:00:00 | 5 | 0 |
| 2008-11-01 00:00:00 | 4 | 1 |
| 2008-11-15 00:00:00 | 3 | 0 |
| 2008-11-14 00:00:00 | 3 | 2 |
| 2008-11-22 00:00:00 | 3 | 1 |
| 2008-11-22 00:00:00 | 3 | 2 |
| 2008-11-30 00:00:00 | 3 | 0 |
| 2008-11-29 00:00:00 | 3 | 2 |
| 2008-11-29 00:00:00 | 4 | 2 |
| 2008-11-29 00:00:00 | 4 | 0 |

## Exercise 3

**Question.** Return 10 matches from 2015/2016 with at least three home goals.

**Learning point.** AND requires both row conditions to be true.

### Final query recorded in the journal

```sql
SELECT season, date, home_team_goal, away_team_goal
FROM `Match`
WHERE season = '2015/2016'
  AND home_team_goal >= 3
LIMIT 10;
```

### Recorded output (source excerpt)

| season | date | home_team_goal | away_team_goal |
| --- | --- | --- | --- |
| 2015/2016 | 2015-07-25 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-07-25 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-07-25 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-07-26 00:00:00 | 3 | 2 |
| 2015/2016 | 2015-10-04 00:00:00 | 4 | 1 |
| 2015/2016 | 2015-10-04 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-10-03 00:00:00 | 3 | 0 |
| 2015/2016 | 2015-10-17 00:00:00 | 3 | 0 |
| 2015/2016 | 2015-10-25 00:00:00 | 3 | 1 |
| 2015/2016 | 2015-10-24 00:00:00 | 3 | 4 |

## Exercise 4

**Question.** Return 10 matches where either side scored at least four goals.

**Learning point.** OR allows either condition to qualify a match.

### Final query recorded in the journal

```sql
SELECT date, home_team_goal, away_team_goal
FROM `Match`
WHERE home_team_goal >= 4
   OR away_team_goal >= 4
LIMIT 10;
```

### Recorded output (source excerpt)

| date | home_team_goal | away_team_goal |
| --- | --- | --- |
| 2008-08-17 00:00:00 | 5 | 0 |
| 2008-11-01 00:00:00 | 4 | 1 |
| 2008-11-29 00:00:00 | 4 | 2 |
| 2008-11-29 00:00:00 | 4 | 0 |
| 2008-12-06 00:00:00 | 5 | 1 |
| 2008-12-06 00:00:00 | 5 | 2 |
| 2008-12-14 00:00:00 | 1 | 4 |
| 2008-12-20 00:00:00 | 4 | 3 |
| 2008-12-20 00:00:00 | 5 | 1 |
| 2009-01-18 00:00:00 | 4 | 1 |

## Exercise 5

**Question.** Show matches with at least three home goals, ordered by home goals descending, limited to ten.

**Learning point.** Filtering and sorting serve different purposes.

### Final query recorded in the journal

```sql
SELECT date, home_team_goal, away_team_goal
FROM `Match`
WHERE home_team_goal >= 3
ORDER BY home_team_goal DESC
LIMIT 10;
```

### Recorded output (source excerpt)

| date | home_team_goal | away_team_goal |
| --- | --- | --- |
| 2010-10-24 00:00:00 | 10 | 0 |
| 2015-12-20 00:00:00 | 10 | 2 |
| 2009-11-22 00:00:00 | 9 | 1 |
| 2013-03-30 00:00:00 | 9 | 2 |
| 2010-11-06 00:00:00 | 9 | 0 |
| 2015-04-05 00:00:00 | 9 | 1 |
| 2010-05-09 00:00:00 | 8 | 0 |
| 2011-08-28 00:00:00 | 8 | 2 |
| 2012-12-23 00:00:00 | 8 | 0 |
| 2014-10-18 00:00:00 | 8 | 0 |

## Exercise 6

**Question.** Count matches in the 2015/2016 season.

**Learning point.** COUNT(*) counts rows after the season filter.

### Final query recorded in the journal

```sql
SELECT COUNT(*) AS match_count
FROM `Match`
WHERE season = '2015/2016';
```

### Recorded output (source excerpt)

| match_count |
| --- |
| 3326 |

## Exercise 7

**Question.** Count matches in each season.

**Learning point.** One output row now represents a season rather than a match.

### Final query recorded in the journal

```sql
SELECT season, COUNT(*) AS match_count
FROM `Match`
GROUP BY season;
```

### Recorded output (source excerpt)

| season | match_count |
| --- | --- |
| 2008/2009 | 3326 |
| 2009/2010 | 3230 |
| 2010/2011 | 3260 |
| 2011/2012 | 3220 |
| 2012/2013 | 3260 |
| 2013/2014 | 3032 |
| 2014/2015 | 3325 |
| 2015/2016 | 3326 |

## Exercise 8

**Question.** Count matches from 2012/2013 onward by season, in ascending season order.

**Learning point.** Filter the source rows before grouping them.

### Final query recorded in the journal

```sql
SELECT season, COUNT(*) AS match_count
FROM `Match`
WHERE season >= '2012/2013'
GROUP BY season
ORDER BY season ASC;
```

### Recorded output (source excerpt)

| season | match_count |
| --- | --- |
| 2012/2013 | 3260 |
| 2013/2014 | 3032 |
| 2014/2015 | 3325 |
| 2015/2016 | 3326 |

## Exercise 9

**Question.** Calculate average home goals by season, in ascending season order.

**Learning point.** The failed attempt compared season with home_team_goal. A grouping task does not require an unrelated WHERE condition.

### Earlier attempt (historical; may be invalid)

```sql
WHERE season = home_team_goal
```

### Final query recorded in the journal

```sql
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
GROUP BY season
ORDER BY season ASC;
```

### Recorded output (source excerpt)

| season | avg_home_goals |
| --- | --- |
| 2008/2009 | 1.50541190619363 |
| 2009/2010 | 1.54117647058824 |
| 2010/2011 | 1.54846625766871 |
| 2011/2012 | 1.57267080745342 |
| 2012/2013 | 1.552 |
| 2013/2014 | 1.57882585751979 |
| 2014/2015 | 1.5203007518797 |
| 2015/2016 | 1.54389657245941 |

## Exercise 10

**Question.** Calculate total home goals by season, in ascending season order.

**Learning point.** SUM measures total goals; COUNT measures matches. The source also compared season counts and averages as a consistency check.

### Final query recorded in the journal

```sql
SELECT season, SUM(home_team_goal) AS total_home_goals
FROM `Match`
GROUP BY season
ORDER BY season ASC;
```

### Recorded output (source excerpt)

| season | total_home_goals |
| --- | --- |
| 2008/2009 | 5007 |
| 2009/2010 | 4978 |
| 2010/2011 | 5048 |
| 2011/2012 | 5064 |
| 2012/2013 | 5053 |
| 2013/2014 | 4787 |
| 2014/2015 | 5055 |
| 2015/2016 | 5135 |

