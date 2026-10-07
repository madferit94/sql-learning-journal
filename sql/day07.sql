-- Day 07: Football joins and team aliases
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day07.md for questions, context and known limitations.

-- Exercise 1: Count matches by league, ordered by count descending and league name ascending.
SELECT l.name AS league_name,
       COUNT(*) AS match_count
FROM league l
JOIN matches m
  ON l.id = m.league_id
GROUP BY l.name
ORDER BY match_count DESC,
         league_name ASC;

-- Exercise 2: Count 2015/2016 matches by league, keeping leagues with at least 300 matches.
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

-- Exercise 3: For 2015/2016, show teams with at least fifteen home matches and rank them by home goals, then name.
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

-- Exercise 4: List 2015/2016 home wins by a margin of at least three, ordered by margin descending and date ascending.
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

-- Exercise 5: Count 2015/2016 away wins by team, keeping at least five and ordering count descending then name ascending.
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

