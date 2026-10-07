-- Day 02: Aggregation and row filters
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day02.md for questions, context and known limitations.

-- Exercise 11: Calculate average away goals by season from 2013/2014 onward and sort by season ascending.
SELECT
season,
AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2013/2014'
GROUP BY season
ORDER BY season ASC;

-- Exercise 12: Rank seasons by average total goals per match, descending.
SELECT
season,
AVG(home_team_goal + away_team_goal) AS avg_total_goals
FROM `Match`
GROUP BY season
ORDER BY avg_total_goals DESC;

-- Exercise 13: Count matches with at least three home goals by season and sort counts descending.
SELECT
season,
COUNT(*) AS high_scoring_home_matches
FROM `Match`
WHERE home_team_goal >= 3
GROUP BY season
ORDER BY high_scoring_home_matches DESC;

-- Exercise 14: Count away wins by season and sort counts descending.
SELECT
season,
COUNT(*) AS away_win_matches
FROM `Match`
WHERE away_team_goal > home_team_goal
GROUP BY season
ORDER BY away_win_matches DESC;

-- Exercise 15: Count draws by season and sort counts descending.
SELECT
season,
COUNT(*) draw_matches
FROM `Match`
WHERE home_team_goal = away_team_goal
GROUP BY season
ORDER BY draw_matches DESC;

