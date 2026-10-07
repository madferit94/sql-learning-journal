-- Day 03: WHERE versus HAVING
-- Historical final recorded queries, NOT a freshly validated solution set.
-- See ../til/en/day03.md for questions, context and known limitations.

-- Exercise 16: Rank seasons from 2010/2011 onward by average home goals descending.
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
ORDER BY avg_home_goals DESC;

-- Exercise 17: Show seasons with at least 3,250 matches, ordered by match count descending.
SELECT season, COUNT(*) AS match_count
FROM `Match`
GROUP BY season
HAVING COUNT(*) >= 3250
ORDER BY match_count DESC;

-- Exercise 18: Show seasons from 2012/2013 onward with average away goals of at least 1.18, sorted by that average descending.
SELECT season, AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2012/2013'
GROUP BY season
HAVING avg_away_goals >= 1.18
ORDER BY avg_away_goals DESC;

-- Exercise 19: Show seasons from 2011/2012 onward with at least 8,800 total goals, sorted by total goals descending.
SELECT season, SUM(home_team_goal + away_team_goal) AS total_goals
FROM `Match`
WHERE season >= '2011/2012'
GROUP BY season
HAVING total_goals >= 8800
ORDER BY total_goals DESC;

-- Exercise 20: For seasons from 2010/2011 onward, calculate match count, average home goals and total goals; retain counts of at least 3,250 and sort by total goals descending.
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

