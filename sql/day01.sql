-- Day 01: Basic selection, filtering and aggregation
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day01.md for questions, context and known limitations.

-- Exercise 1: Return 10 matches from the 2015/2016 season, showing season, date and both teams' goals.
SELECT season, date, home_team_goal, away_team_goal
FROM `Match`
WHERE season = '2015/2016'
LIMIT 10;

-- Exercise 2: Return 10 matches with at least three home goals.
SELECT date, home_team_goal, away_team_goal
FROM `Match`
WHERE home_team_goal >= 3
LIMIT 10;

-- Exercise 3: Return 10 matches from 2015/2016 with at least three home goals.
SELECT season, date, home_team_goal, away_team_goal
FROM `Match`
WHERE season = '2015/2016'
  AND home_team_goal >= 3
LIMIT 10;

-- Exercise 4: Return 10 matches where either side scored at least four goals.
SELECT date, home_team_goal, away_team_goal
FROM `Match`
WHERE home_team_goal >= 4
   OR away_team_goal >= 4
LIMIT 10;

-- Exercise 5: Show matches with at least three home goals, ordered by home goals descending, limited to ten.
SELECT date, home_team_goal, away_team_goal
FROM `Match`
WHERE home_team_goal >= 3
ORDER BY home_team_goal DESC
LIMIT 10;

-- Exercise 6: Count matches in the 2015/2016 season.
SELECT COUNT(*) AS match_count
FROM `Match`
WHERE season = '2015/2016';

-- Exercise 7: Count matches in each season.
SELECT season, COUNT(*) AS match_count
FROM `Match`
GROUP BY season;

-- Exercise 8: Count matches from 2012/2013 onward by season, in ascending season order.
SELECT season, COUNT(*) AS match_count
FROM `Match`
WHERE season >= '2012/2013'
GROUP BY season
ORDER BY season ASC;

-- Exercise 9: Calculate average home goals by season, in ascending season order.
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
GROUP BY season
ORDER BY season ASC;

-- Exercise 10: Calculate total home goals by season, in ascending season order.
SELECT season, SUM(home_team_goal) AS total_home_goals
FROM `Match`
GROUP BY season
ORDER BY season ASC;

