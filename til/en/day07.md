# Day 07 — Football joins and team aliases

[한국어 원기록](../ko/day07.md) · [Index](../../README.md) · [Editorial notes](../../docs/editorial.en.md)

This is an edited English study edition of the Korean Notion journal: all exercises are included, with concise translations of the questions and learning points. Repeated explanations are condensed. SQL and available result tables are transcribed from the source, not rerun for this publication. Historical attempts may be invalid.

## Exercise 1

**Question.** Count matches by league, ordered by count descending and league name ascending.

**Learning point.** Join league.id to matches.league_id. Matching unrelated primary keys can run while answering the wrong question.

### Earlier attempt (historical; may be invalid)

```sql
SELECT l.name AS league_name, COUNT(*) AS match_count
FROM league l
JOIN `Match` m ON l.id = m.id
ORDER BY maect_coun DESC, league_name ASC;
```

### Final query recorded in the journal

```sql
SELECT l.name AS league_name,
       COUNT(*) AS match_count
FROM league l
JOIN matches m
  ON l.id = m.league_id
GROUP BY l.name
ORDER BY match_count DESC,
         league_name ASC;
```

### Recorded output (source excerpt)

| league_name | match_count |
| --- | --- |
| England Premier League | 3040 |
| France Ligue 1 | 3040 |
| Spain LIGA BBVA | 3040 |
| Italy Serie A | 3017 |
| Germany 1. Bundesliga | 2448 |
| Netherlands Eredivisie | 2448 |
| Portugal Liga ZON Sagres | 2052 |
| Poland Ekstraklasa | 1920 |
| Scotland Premier League | 1824 |
| Belgium Jupiler League | 1728 |
| Switzerland Super League | 1422 |

## Exercise 2

**Question.** Count 2015/2016 matches by league, keeping leagues with at least 300 matches.

**Learning point.** Apply the season filter before grouping; apply the count threshold afterward.

### Final query recorded in the journal

```sql
SELECT l.name AS league_name,
       COUNT(*) AS match_count
FROM league l
JOIN matches m
  ON l.id = m.league_id
WHERE m.season = '2015/2016'
GROUP BY l.name
HAVING COUNT(*) >= 300
ORDER BY match_count DESC,
         l.name ASC;
```

### Recorded output (source excerpt)

| league_name | match_count |
| --- | --- |
| England Premier League | 380 |
| France Ligue 1 | 380 |
| Italy Serie A | 380 |
| Spain LIGA BBVA | 380 |
| Germany 1. Bundesliga | 306 |
| Netherlands Eredivisie | 306 |
| Portugal Liga ZON Sagres | 306 |

## Exercise 3

**Question.** For 2015/2016, show teams with at least fifteen home matches and rank them by home goals, then name.

**Learning point.** Use the home-team key. Selecting a team name while grouping only by ID depends on schema constraints and SQL mode.

### Final query recorded in the journal

```sql
SELECT t.team_long_name AS team_name,
       COUNT(*) AS home_match_count,
       SUM(m.home_team_goal) AS total_home_goals
FROM team t
JOIN matches m
  ON t.team_api_id = m.home_team_api_id
WHERE m.season = '2015/2016'
GROUP BY t.team_api_id
HAVING COUNT(*) >= 15
ORDER BY total_home_goals DESC,
         team_name ASC;
```

### Recorded output (source excerpt)

| team_name | home_match_count | total_home_goals |
| --- | --- | --- |
| Real Madrid CF | 19 | 70 |
| FC Barcelona | 19 | 67 |
| Paris Saint-Germain | 19 | 59 |
| Celtic | 19 | 55 |
| SL Benfica | 17 | 52 |
| FC Bayern Munich | 17 | 51 |
| BSC Young Boys | 18 | 50 |
| Ajax | 17 | 49 |
| Borussia Dortmund | 17 | 49 |
| Napoli | 19 | 49 |
| Manchester City | 19 | 47 |

## Exercise 4

**Question.** List 2015/2016 home wins by a margin of at least three, ordered by margin descending and date ascending.

**Learning point.** This is a match-level query, not an aggregate. Join team twice using separate home and away aliases.

### Earlier attempt (historical; may be invalid)

```sql
SELECT m.match_date,
       t.team_long_name AS home_team,
       t.team_long_name AS away_name,
       SUM(home_team_goal) AS home_goals,
       SUM(away_team_goal) AS away_goals
FROM team t
JOIN matches m
  ON t.team_long_name = m.home_team_api_id
 AND t.team_long_name = m.away_team_api_id
WHERE m.season = '2015/2016'
GROUP BY t.team_long_name
HAVING (home_goals - away_goals) >= 3;
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
  AND (m.home_team_goal - m.away_team_goal) >= 3
ORDER BY (m.home_team_goal - m.away_team_goal) DESC,
         m.match_date ASC;
```

### Recorded output (source excerpt)

| match_date | home_team | away_team | home_goals | away_goals |
| --- | --- | --- | --- | --- |
| 2015-12-20 | Real Madrid CF | Rayo Vallecano | 10 | 2 |
| 2016-01-19 | Celtic | Hamilton Academical FC | 8 | 1 |
| 2016-04-09 | BSC Young Boys | Lugano | 7 | 0 |
| 2016-05-15 | Celtic | Motherwell | 7 | 0 |

## Exercise 5

**Question.** Count 2015/2016 away wins by team, keeping at least five and ordering count descending then name ascending.

**Learning point.** Use away_team_api_id for the team join and compare away goals with home goals.

### Earlier attempt (historical; may be invalid)

```sql
SELECT a.team_long_name AS team_name,
       COUNT(*) AS away_win_count
FROM matches m
JOIN team h
  ON m.home_team_api_id = h.team_long_name
JOIN team a
  ON m.away_team_api_id = a.team_long_name
WHERE m.season = '2015/2016'
  AND m.away_team_goal > m.home_team_goal
ORDER BY (away_team_goal > home_team_goal) DESC,
         team_name ASC
LIMIT 10;
```

### Final query recorded in the journal

```sql
SELECT a.team_long_name AS team_name,
       COUNT(*) AS away_win_count
FROM matches m
JOIN team a
  ON m.away_team_api_id = a.team_api_id
WHERE m.season = '2015/2016'
  AND m.away_team_goal > m.home_team_goal
GROUP BY a.team_long_name
HAVING COUNT(*) >= 5
ORDER BY away_win_count DESC,
         team_name ASC;
```

### Recorded output (source excerpt)

| team_name | away_win_count |
| --- | --- |
| Paris Saint-Germain | 15 |
| SL Benfica | 14 |
| Sporting CP | 14 |
| Atlético Madrid | 13 |
| FC Barcelona | 13 |
| FC Bayern Munich | 13 |
| Juventus | 13 |
| PSV | 13 |
| Ajax | 12 |
| Celtic | 12 |
| FC Basel | 12 |
| Real Madrid CF | 12 |
| FC Porto | 11 |
| Leicester City | 11 |
| Aberdeen | 10 |
| Borussia Dortmund | 10 |
| Roma | 10 |

