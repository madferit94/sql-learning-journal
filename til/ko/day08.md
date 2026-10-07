# Day 08 — 학습 원기록

[English](../en/day08.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### ⚽ Day8 — 팀·리그별 JOIN·집계·CASE WHEN
# SQL 학습 기록 — Day 8
## ⚽ Sports SQL Day 5 — JOIN + GROUP BY + CASE WHEN
- 환경: MySQL 8.4
## 🎯 오늘의 학습 목표
- `JOIN + GROUP BY + SUM/COUNT` 조합 복습
- 같은 `team` 테이블을 홈/원정 역할에 따라 두 번 JOIN하기
- `WHERE`와 `HAVING`의 역할 구분하기
- `CASE WHEN`으로 행을 조건에 따라 분류하기
- 여러 기준으로 집계할 때 `GROUP BY`에 집계 단위를 정확하게 표현하기
---
## 📌 주요 컬럼


| English column | Korean meaning | table | actual role |
| --- | --- | --- | --- |
| `id` | 리그 ID | `league` | `matches.league_id`와 JOIN |
| `name` | 리그 이름 | `league` | 리그명 출력 |
| `team_api_id` | 팀 API ID | `team` | 경기 테이블의 홈/원정 팀 ID와 JOIN |
| `team_long_name` | 팀 이름 | `team` | 팀명 출력 |
| `league_id` | 리그 ID | `matches` | 경기와 리그 연결 |
| `season` | 시즌 | `matches` | `2015/2016` 시즌 필터 |
| `match_date` | 경기 날짜 | `matches` | 경기 날짜 출력 및 정렬 |
| `home_team_api_id` | 홈 팀 ID | `matches` | 홈 팀 JOIN |
| `away_team_api_id` | 원정 팀 ID | `matches` | 원정 팀 JOIN |
| `home_team_goal` | 홈 팀 득점 | `matches` | 홈승/원정승/무승부 판별 |
| `away_team_goal` | 원정 팀 득점 | `matches` | 원정 득점 합계 및 경기 결과 판별 |


---
# 문제 1 — 팀별 원정 총 득점
## 문제
2015/2016 시즌 각 팀의 원정 경기 총 득점을 구한다.
조건:
- 원정 총 득점이 20골 이상인 팀만 출력
- `total_away_goals` 내림차순
- 동률이면 `team_name` 오름차순
출력:
`team_name | total_away_goals`
## 첫 시도
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
## 오류
SQL 구조 자체는 정확했다.
문제 조건은:
```sql
total_away_goals >= 20
```
이었지만 첫 시도에서:
```sql
HAVING total_away_goals >= 3
```
으로 작성했다.
즉 SQL 개념 오류가 아니라 **문제 조건을 잘못 읽은 오류**였다.
## 최종 쿼리
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
## 실제 결과
**109 rows IN SET (0.04 sec)**
상위 결과:


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


모든 출력 팀은 원정 총 득점 20골 이상.
## 핵심 개념
```sql
SUM()
```
은 득점처럼 **값 자체를 합산**할 때 사용한다.
```sql
GROUP BY team_name
```
으로 팀별 집계를 수행한 뒤,
```sql
HAVING total_away_goals >= 20
```
으로 집계 결과를 필터링한다.
---
# 문제 2 — 원정 팀이 4골 차 이상으로 승리한 경기
## 문제
2015/2016 시즌 경기 중 원정 팀이 홈 팀보다 최소 4골 이상 많이 득점한 경기를 조회한다.
출력:
`match_date | home_team | away_team | home_goals | away_goals`
정렬:
1. 득점 차이 내림차순
2. 경기 날짜 오름차순
## 첫 시도
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
## 첫 실행 결과
**62 rows IN SET (0.02 sec)**
결과 자체는 정상적으로 출력되었다.
MySQL에서는 SELECT alias를 `HAVING`에서 사용할 수 있기 때문에 실행됐다.
하지만 이 조건은 그룹화된 결과에 대한 조건이 아니라 **각 경기 행에 대한 조건**이다.
따라서 의미상 `WHERE`에서 처리하는 것이 더 적절하다.
## 최종 쿼리
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
## 실제 결과
**62 rows IN SET (0.03 sec)**
상위 사례:


| match_date | home_team | away_team | home_goals | away_goals |
| --- | --- | --- | --- | --- |
| 2016-03-13 | ES Troyes AC | Paris Saint-Germain | 0 | 9 |
| 2016-04-20 | Deportivo | FC Barcelona | 0 | 8 |
| 2016-04-17 | St. Gallen | FC Basel | 0 | 7 |


## 핵심 개념
같은 `team` 테이블을 역할에 따라 두 번 사용할 수 있다.
```sql
JOIN team h
    ON m.home_team_api_id = h.team_api_id

JOIN team a
    ON m.away_team_api_id = a.team_api_id
```
- `h` = home team
- `a` = away team
또한:
```plain text
WHERE  → 개별 행 필터
HAVING → GROUP BY 이후 집계 결과 필터
```
이번 문제는 경기 한 행씩 검사하므로 `WHERE`가 적절하다.
---
# 문제 3 — 리그별 홈승 경기 수
## 문제
2015/2016 시즌 각 리그의 홈승 경기 수를 구한다.
홈승:
```plain text
home_team_goal > away_team_goal
```
조건:
- 홈승이 100경기 이상인 리그만 출력
출력:
`league_name | home_win_count`
정렬:
1. 홈승 수 내림차순
2. 리그 이름 오름차순
## 첫 시도
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
## 첫 실행 결과


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
| Scotland Premier League | 93 |
| Poland Ekstraklasa | 91 |
| Switzerland Super League | 80 |


**11 rows IN SET (0.03 sec)**
## 오류
문제의 조건:
```plain text
홈승이 100경기 이상인 리그
```
를 적용하지 않았다.
홈승 수는 `COUNT(*)`로 집계한 결과이므로 `WHERE`가 아니라 `HAVING`이 필요하다.
## 최종 쿼리
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
## 실제 결과


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


**8 rows IN SET (0.02 sec)**
## 핵심 개념
SQL 실행 논리를 단순화하면:
```plain text
WHERE
↓
GROUP BY
↓
HAVING
↓
ORDER BY
```
이번 문제에서는:
```plain text
WHERE
→ 2015/2016 시즌의 홈승 경기만 남김

GROUP BY
→ 리그별로 묶음

COUNT(*)
→ 각 리그의 홈승 경기 수 계산

HAVING
→ 그중 100승 이상인 리그만 남김
```
---
# 문제 4 — CASE WHEN으로 경기 결과 분류
## 문제
2015/2016 시즌 경기를 다음 기준으로 분류한다.
```plain text
home_team_goal > away_team_goal → Home Win
home_team_goal < away_team_goal → Away Win
home_team_goal = away_team_goal → Draw
```
출력:
`match_date | home_goals | away_goals | result`
경기 날짜 오름차순.
## 첫 시도
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
## 오류
MySQL 오류:
```plain text
ERROR 1064 (42000)
```
`CASE WHEN`의 조건 논리는 맞았지만 **CASE의 위치가 잘못됐다.**
`result`는 원래 `matches`에 존재하는 컬럼이 아니다.
```sql
CASE ... END AS result
```
를 통해 SELECT 단계에서 새로 만들어지는 컬럼이다.
따라서 CASE 표현식 자체가 SELECT 항목에 들어가야 한다.
## 최종 쿼리
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
## 실제 결과 일부


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


## 핵심 개념
`CASE WHEN`은 조건에 따라 새로운 값을 생성할 수 있다.
기본 형태:
```sql
CASE
    WHEN 조건1 THEN 값1
    WHEN 조건2 THEN 값2
    ELSE 값3
END AS alias
```
이번 문제에서는 마지막 조건을 다음처럼 작성해도 된다.
```sql
ELSE 'Draw'
```
홈승도 아니고 원정승도 아니면 남는 경우는 무승부이기 때문이다.
---
# 문제 5 — 리그별 경기 결과별 경기 수
## 문제
2015/2016 시즌 각 리그의 경기 결과별 경기 수를 구한다.
경기 결과:
```plain text
Home Win
Away Win
Draw
```
출력:
`league_name | result | match_count`
정렬:
1. `league_name` 오름차순
2. 같은 리그에서는 `match_count` 내림차순
## 첫 시도
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
## 첫 번째 오류
```sql
GROUP BY result
```
만 사용하면 모든 리그를 합친 뒤:
```plain text
Home Win
Away Win
Draw
```
세 그룹으로만 나누게 된다.
문제에서 원하는 집계 단위는:
```plain text
리그별 + 경기 결과별
```
이다.
---
## 두 번째 시도
```sql
GROUP BY league_name
```
이번에는 반대로 리그만 기준으로 묶었다.
이 경우:
```plain text
England Premier League
France Ligue 1
...
```
처럼 리그 하나당 하나의 그룹이 되므로 경기 결과별 분리가 되지 않는다.
---
## 세 번째 시도
```sql
GROUP BY league_name AND resultORDER BY ...
```
## 세 번째 오류
여러 GROUP BY 기준을 나열할 때는 `AND`가 아니라 쉼표 `,`를 사용한다.
```plain text
AND → 조건을 연결
,   → GROUP BY 기준을 나열
```
또한:
```sql
resultORDER
```
에서 `result`와 `ORDER` 사이의 공백이 빠졌다.
---
## 최종 쿼리
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
## 실제 결과


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


**33 rows IN SET (0.07 sec)**
## 핵심 개념
`GROUP BY`는 문제에서 요구하는 **집계 결과 한 행의 단위**를 생각해야 한다.
문제:
> 각 리그의 경기 결과별 경기 수
따라서 한 행을 결정하는 기준은 두 개다.
```plain text
league_name + result
```
SQL:
```sql
GROUP BY league_name, result
```
---
# 🔍 오늘의 주요 오류 패턴
## 1. SQL 개념은 맞았지만 문제 조건을 잘못 읽음
P1:
```sql
HAVING total_away_goals >= 3
```
문제는 `>= 20`.
→ SQL 문법보다 **문제 조건 확인 과정**의 문제.
---
## 2. WHERE와 HAVING 구분
P2에서:
```sql
HAVING (away_goals - home_goals) >= 4
```
가 MySQL에서는 실행됐지만, 경기 한 행씩 필터링하는 조건이므로:
```sql
WHERE (m.away_team_goal - m.home_team_goal) >= 4
```
가 의미상 더 적절하다.
P3에서는 반대로 `COUNT(*) >= 100`이 집계 후 조건이므로:
```sql
HAVING COUNT(*) >= 100
```
이 필요했다.
정리:
```plain text
원본 행 조건 → WHERE
집계 결과 조건 → HAVING
```
---
## 3. CASE WHEN의 위치
처음에는:
```sql
FROM matches
CASE WHEN ...
```
으로 작성했다.
하지만 CASE는 새로운 값을 만드는 표현식이므로:
```sql
SELECT
    ...,
    CASE
        WHEN ...
    END AS result
FROM ...
```
형태로 SELECT 안에 위치한다.
---
## 4. GROUP BY의 집계 단위
오늘 가장 중요한 반복 오류.
P5에서:
```sql
GROUP BY result
```
→ 결과별만 집계
```sql
GROUP BY league_name
```
→ 리그별만 집계
최종:
```sql
GROUP BY league_name, result
```
→ 리그별 + 결과별 집계
문제를 읽을 때:
> “무엇별 + 무엇별”
이라는 표현이 보이면 GROUP BY 기준이 여러 개인지 확인한다.
---
## 5. 여러 GROUP BY 기준은 쉼표
잘못된 형태:
```sql
GROUP BY league_name AND result
```
올바른 형태:
```sql
GROUP BY league_name, result
```
`AND`는 조건식 연결에 사용하고, GROUP BY 컬럼은 쉼표로 나열한다.
---
# 📝 오늘의 회고
오늘은 전날보다 JOIN 작성이 확실히 나아졌다.
특히 P2에서 같은 `team` 테이블을:
```sql
JOIN team h
    ON m.home_team_api_id = h.team_api_id

JOIN team a
    ON m.away_team_api_id = a.team_api_id
```
처럼 홈 팀과 원정 팀 역할로 나누어 스스로 작성했다.
이 부분은 이전 세션에서 크게 막혔던 내용이므로 실제 개선된 부분이다.
또한 처음 사용한 `CASE WHEN`에서도 조건 자체:
```sql
home_team_goal > away_team_goal
home_team_goal < away_team_goal
home_team_goal = away_team_goal
```
는 처음부터 정확하게 작성했다.
현재 가장 보완해야 할 부분은 `GROUP BY`이다.
단순히 문법을 기억하는 것보다 문제에서 요구하는:
```plain text
“결과 한 행이 무엇을 의미하는가?”
```
를 먼저 생각할 필요가 있다.
예:
```plain text
리그별 홈승 수
→ 한 행 = 리그
→ GROUP BY league_name

리그별 경기 결과별 경기 수
→ 한 행 = 리그 + 경기 결과
→ GROUP BY league_name, result
```
---
# ➡️ 다음 학습 포인트
다음 Sports SQL에서는 `CASE WHEN`을 한 단계 더 발전시킨다.
핵심 목표:
```plain text
1. CASE WHEN 복습
2. SUM(CASE WHEN ... THEN 1 ELSE 0 END)
3. 조건부 집계
4. 팀별 홈승 / 원정승을 하나의 결과로 만들기
5. GROUP BY 집계 단위 재확인
```
다음 단계에서 익혀야 할 형태:
```sql
SUM(
    CASE
        WHEN 조건 THEN 1
        ELSE 0
    END
)
```
이 패턴을 익히면 단순히 행마다 `Home Win`, `Away Win`이라고 표시하는 것을 넘어 한 행에 여러 조건의 집계 결과를 만들 수 있다.
이후 진행 방향:
```plain text
CASE WHEN
→ 조건부 집계
→ CTE
→ ROW_NUMBER / RANK / DENSE_RANK
→ PARTITION BY
→ LAG / LEAD
→ SUM() OVER() / AVG() OVER()
```

---
