# Day 08 — Football classification and grouped outcomes

[한국어 원기록](../ko/day08.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Rank teams with at least twenty away goals in 2015/2016.

**Learning point.** The earlier threshold did not match the question. Distinguish a condition on one match from a threshold on a season total.

### Earlier attempt (historical; may be invalid)

```sql
SELECT t.team_long_name AS team_name,
       SUM(away_team_goal) AS total_away_goals
FROM team t
JOIN matches m
    ON t.team_api_id = m.away_team_api_id
WHERE m.season = '2015/2016'
GROUP BY team_name
HAVING total_away_goals >= 3
ORDER BY total_away_goals DESC, team_name ASC;
```

### Final query recorded in the journal

```sql
SELECT t.team_long_name AS team_name,
       SUM(away_team_goal) AS total_away_goals
FROM team t
JOIN matches m
    ON t.team_api_id = m.away_team_api_id
WHERE m.season = '2015/2016'
GROUP BY team_name
HAVING total_away_goals >= 20
ORDER BY total_away_goals DESC, team_name ASC;
```

### Recorded output (source excerpt)

| team_name | total_away_goals |
| --- | --- |
| PSV | 47 |
| FC Barcelona | 45 |
| FC Basel | 44 |
| Paris Saint-Germain | 43 |
| Real Madrid CF | 40 |
| Sporting CP | 40 |
| Roma | 39 |
| Celtic | 38 |
| Juventus | 38 |
| SL Benfica | 36 |

## Exercise 2

**Question.** List 2015/2016 away wins by at least four goals, ordered by margin descending then date ascending.

**Learning point.** Use WHERE for match-level score conditions. MySQL may allow aliases in HAVING, but that is not a reason to confuse row filters with group filters.

### Earlier attempt (historical; may be invalid)

```sql
SELECT m.match_date,
       h.team_long_name AS home_team,
       a.team_long_name AS away_team,
       m.home_team_goal AS home_goals,
       m.away_team_goal AS away_goals
FROM matches m
JOIN team h
    ON m.home_team_api_id = h.team_api_id
JOIN team a
    ON m.away_team_api_id = a.team_api_id
WHERE m.season = '2015/2016'
HAVING (away_goals - home_goals) >= 4
ORDER BY (away_goals - home_goals) DESC,
         m.match_date ASC;
```

### Final query recorded in the journal

```sql
SELECT m.match_date,
       h.team_long_name AS home_team,
       a.team_long_name AS away_team,
       m.home_team_goal AS home_goals,
       m.away_team_goal AS away_goals
FROM matches m
JOIN team h
    ON m.home_team_api_id = h.team_api_id
JOIN team a
    ON m.away_team_api_id = a.team_api_id
WHERE m.season = '2015/2016'
  AND (m.away_team_goal - m.home_team_goal) >= 4
ORDER BY (away_goals - home_goals) DESC,
         m.match_date ASC;
```

### Recorded output (source excerpt)

| match_date | home_team | away_team | home_goals | away_goals |
| --- | --- | --- | --- | --- |
| 2016-03-13 | ES Troyes AC | Paris Saint-Germain | 0 | 9 |
| 2016-04-20 | Deportivo | FC Barcelona | 0 | 8 |
| 2016-04-17 | St. Gallen | FC Basel | 0 | 7 |

## Exercise 3

**Question.** Count 2015/2016 home wins by league, keeping counts of at least one hundred.

**Learning point.** Filter home wins before grouping by league.

### Earlier attempt (historical; may be invalid)

```sql
SELECT l.name AS league_name,
       COUNT(*) AS home_win_count
FROM league l
JOIN matches m
    ON l.id = m.league_id
WHERE m.season = '2015/2016'
  AND (m.home_team_goal > m.away_team_goal)
GROUP BY league_name
ORDER BY home_win_count DESC, league_name ASC;
```

### Final query recorded in the journal

```sql
SELECT l.name AS league_name,
       COUNT(*) AS home_win_count
FROM league l
JOIN matches m
    ON l.id = m.league_id
WHERE m.season = '2015/2016'
  AND (m.home_team_goal > m.away_team_goal)
GROUP BY league_name
HAVING COUNT(*) >= 100
ORDER BY home_win_count DESC, league_name ASC;
```

### Recorded output (source excerpt)

| league_name | home_win_count |
| --- | --- |
| Spain LIGA BBVA | 183 |
| Italy Serie A | 175 |
| France Ligue 1 | 160 |
| England Premier League | 157 |
| Netherlands Eredivisie | 137 |
| Germany 1. Bundesliga | 135 |
| Portugal Liga ZON Sagres | 133 |
| Belgium Jupiler League | 115 |

## Exercise 4

**Question.** Classify 2015/2016 matches as Home Win, Away Win or Draw, ordered by date.

**Learning point.** CASE belongs in SELECT when producing a new output column.

### Earlier attempt (historical; may be invalid)

```sql
SELECT match_date,
       home_team_goal AS home_goals,
       away_team_goal AS away_goals,
       result
FROM matches
CASE
    WHEN home_team_goal > away_team_goal THEN 'Home Win'
    WHEN home_team_goal < away_team_goal THEN 'Away Win'
    WHEN home_team_goal = away_team_goal THEN 'Draw'
END AS result
WHERE season = '2015/2016'
ORDER BY match_date ASC;
```

### Final query recorded in the journal

```sql
SELECT match_date,
       home_team_goal AS home_goals,
       away_team_goal AS away_goals,
       CASE
           WHEN home_team_goal > away_team_goal THEN 'Home Win'
           WHEN home_team_goal < away_team_goal THEN 'Away Win'
           WHEN home_team_goal = away_team_goal THEN 'Draw'
       END AS result
FROM matches
WHERE season = '2015/2016'
ORDER BY match_date ASC;
```

### Recorded output (source excerpt)

| match_date | home_goals | away_goals | result |
| --- | --- | --- | --- |
| 2015-07-17 00:00:00 | 0 | 1 | Away Win |
| 2015-07-17 00:00:00 | 1 | 1 | Draw |
| 2015-07-18 00:00:00 | 1 | 2 | Away Win |
| 2015-07-18 00:00:00 | 0 | 2 | Away Win |
| 2015-07-18 00:00:00 | 1 | 1 | Draw |
| 2015-07-18 00:00:00 | 2 | 2 | Draw |
| 2015-07-19 00:00:00 | 1 | 4 | Away Win |
| 2015-07-19 00:00:00 | 3 | 2 | Home Win |
| 2015-07-19 00:00:00 | 2 | 0 | Home Win |

## Exercise 5

**Question.** Count 2015/2016 matches by league and result category, ordered by league then count descending.

**Learning point.** Both league and result category define a group. Remember the comma after a CASE expression when another selected expression follows.

### Earlier attempt (historical; may be invalid)

```sql
SELECT l.name AS league_name,
       CASE
           WHEN m.home_team_goal > m.away_team_goal THEN 'Home Win'
           WHEN m.home_team_goal < m.away_team_goal THEN 'Away Win'
           WHEN m.home_team_goal = m.away_team_goal THEN 'Draw'
       END AS result,
       COUNT(*) AS match_count
FROM league l
JOIN matches m
    ON l.id = m.league_id
WHERE m.season = '2015/2016'
GROUP BY result
ORDER BY league_name ASC, match_count DESC;
```

### Final query recorded in the journal

```sql
SELECT l.name AS league_name,
       CASE
           WHEN m.home_team_goal > m.away_team_goal THEN 'Home Win'
           WHEN m.home_team_goal < m.away_team_goal THEN 'Away Win'
           WHEN m.home_team_goal = m.away_team_goal THEN 'Draw'
       END AS result,
       COUNT(*) AS match_count
FROM league l
JOIN matches m
    ON l.id = m.league_id
WHERE m.season = '2015/2016'
GROUP BY league_name, result
ORDER BY league_name ASC, match_count DESC;
```

### Recorded output (source excerpt)

| league_name | result | match_count |
| --- | --- | --- |
| Belgium Jupiler League | Home Win | 115 |
| Belgium Jupiler League | Away Win | 66 |
| Belgium Jupiler League | Draw | 59 |
| England Premier League | Home Win | 157 |
| England Premier League | Away Win | 116 |
| England Premier League | Draw | 107 |
| France Ligue 1 | Home Win | 160 |
| France Ligue 1 | Away Win | 112 |
| France Ligue 1 | Draw | 108 |
| Germany 1. Bundesliga | Home Win | 135 |
| Germany 1. Bundesliga | Away Win | 100 |
| Germany 1. Bundesliga | Draw | 71 |
| Italy Serie A | Home Win | 175 |
| Italy Serie A | Away Win | 110 |
| Italy Serie A | Draw | 95 |
| Netherlands Eredivisie | Home Win | 137 |
| Netherlands Eredivisie | Away Win | 95 |
| Netherlands Eredivisie | Draw | 74 |
| Poland Ekstraklasa | Home Win | 91 |
| Poland Ekstraklasa | Away Win | 75 |
| Poland Ekstraklasa | Draw | 74 |
| Portugal Liga ZON Sagres | Home Win | 133 |
| Portugal Liga ZON Sagres | Away Win | 97 |
| Portugal Liga ZON Sagres | Draw | 76 |
| Scotland Premier League | Home Win | 93 |
| Scotland Premier League | Away Win | 83 |
| Scotland Premier League | Draw | 52 |
| Spain LIGA BBVA | Home Win | 183 |
| Spain LIGA BBVA | Away Win | 105 |
| Spain LIGA BBVA | Draw | 92 |
| Switzerland Super League | Home Win | 80 |
| Switzerland Super League | Away Win | 53 |
| Switzerland Super League | Draw | 47 |

