-- Day 08: Football classification and grouped outcomes
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day08.md for questions, context and known limitations.

-- Exercise 1: Rank teams with at least twenty away goals in 2015/2016.
SELECT t.team_long_name AS team_name,
       SUM(away_team_goal) AS total_away_goals
FROM team t
JOIN matches m
    ON t.team_api_id = m.away_team_api_id
WHERE m.season = '2015/2016'
GROUP BY team_name
HAVING total_away_goals >= 20
ORDER BY total_away_goals DESC, team_name ASC;

-- Exercise 2: List 2015/2016 away wins by at least four goals, ordered by margin descending then date ascending.
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

-- Exercise 3: Count 2015/2016 home wins by league, keeping counts of at least one hundred.
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

-- Exercise 4: Classify 2015/2016 matches as Home Win, Away Win or Draw, ordered by date.
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

-- Exercise 5: Count 2015/2016 matches by league and result category, ordered by league then count descending.
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

