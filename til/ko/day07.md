# Day 07 — 학습 원기록

[English](../en/day07.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### ⚽ Day7 — JOIN·리그·팀별 경기 분석
# SQL 학습 기록 — Day 7
## ⚽ Sports SQL Day (2026-09-21) — JOIN + 경기 분석
- 환경: MySQL 8.4
## 🎯 오늘의 학습 목표
- `matches`, `league`, `team` 테이블의 관계를 파악하고 올바른 키로 JOIN하기
- `WHERE`와 `HAVING`의 역할 구분하기
- 개별 경기 조회와 팀/리그 단위 집계를 구분하기
- 같은 `team` 테이블을 홈팀과 원정팀 역할로 두 번 JOIN하기
- 집계 결과와 계산식을 기준으로 정렬하기
- 여러 SQL 문법을 하나의 쿼리로 안정적으로 조립하기
---
## 🗂 주요 테이블 및 컬럼
### league


| column name | type | nullable | 의미 |
| --- | --- | --- | --- |
| id | integer | false | 리그 ID |
| country_id | integer | true | 국가 ID |
| name | varchar | true | 리그명 |


### team


| column name | type | nullable | 의미 |
| --- | --- | --- | --- |
| id | integer | false | 테이블 내부 ID |
| team_api_id | integer | true | 팀 API ID |
| team_fifa_api_id | integer | true | FIFA 팀 ID |
| team_long_name | varchar | true | 팀 전체 이름 |
| team_short_name | varchar | true | 팀 약칭 |


### matches


| column name | type | nullable | 의미 |
| --- | --- | --- | --- |
| id | integer | false | 경기 ID |
| country_id | integer | true | 국가 ID |
| league_id | integer | true | 리그 ID |
| season | varchar | true | 시즌 |
| stage | integer | true | 라운드 |
| match_date | datetime | true | 경기 날짜 |
| match_api_id | integer | true | 경기 API ID |
| home_team_api_id | integer | true | 홈팀 API ID |
| away_team_api_id | integer | true | 원정팀 API ID |
| home_team_goal | integer | true | 홈팀 득점 |
| away_team_goal | integer | true | 원정팀 득점 |


### 주요 JOIN 관계
- `matches.league_id = league.id`
- `matches.home_team_api_id = team.team_api_id`
- `matches.away_team_api_id = team.team_api_id`
---
# 문제 1 — 리그별 전체 경기 수
## 문제
`league`와 `matches` 테이블에서 각 리그의 이름과 전체 경기 수를 조회한다.
결과는 경기 수가 많은 순으로 정렬하고, 경기 수가 같다면 리그 이름을 오름차순으로 정렬한다.
### 출력


| league_name | match_count |
| --- | --- |
| ... | ... |


---
## ❌ 첫 시도
```sql
SELECT l.name AS league_name, COUNT(*) AS match_count
FROM league l
JOIN `Match` m ON l.id = m.id
ORDER BY maect_coun DESC, league_name ASC;
```
## 오류
### 1. JOIN 기준 오류
```sql
l.id = m.id
```
`league.id`와 경기 자체의 `id`를 연결했다.
리그와 경기를 연결하려면 다음 관계를 사용해야 한다.
```sql
l.id = m.league_id
```
### 2. `GROUP BY` 누락
문제는 전체 경기 수가 아니라 **리그별 경기 수**를 요구한다.
따라서 리그 단위로 묶어야 한다.
### 3. alias 오타
```sql
maect_coun
```
실제 alias는:
```sql
match_count
```
### 4. `match` 테이블명 문제
MySQL에서 `match`가 문법과 충돌할 수 있어 테이블명을 다음과 같이 변경했다.
```sql
RENAME TABLE `match` TO matches;
```
앞으로 Sports DB에서는 `matches`를 사용한다.
---
## ✅ 최종 쿼리
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
## 📊 실제 결과


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


**11 rows**
## 💡 핵심 개념
```sql
COUNT(*)
```
만 사용하면 전체 행 수를 센다.
문제에서 **리그별** 경기 수를 요구하므로:
```sql
GROUP BY l.name
```
으로 리그별 그룹을 만든 뒤 각 그룹의 행 수를 계산해야 한다.
---
# 문제 2 — 2015/2016 시즌 리그별 경기 수
## 문제
`league`와 `matches` 테이블에서 2015/2016 시즌의 리그별 경기 수를 조회한다.
경기 수가 300경기 이상인 리그만 출력한다.
결과는 경기 수를 기준으로 내림차순 정렬하고, 경기 수가 같다면 리그 이름을 오름차순으로 정렬한다.
### 출력


| league_name | match_count |
| --- | --- |
| ... | ... |


---
## ✅ 첫 시도 — 정답
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
## 📊 실제 결과


| league_name | match_count |
| --- | --- |
| England Premier League | 380 |
| France Ligue 1 | 380 |
| Italy Serie A | 380 |
| Spain LIGA BBVA | 380 |
| Germany 1. Bundesliga | 306 |
| Netherlands Eredivisie | 306 |
| Portugal Liga ZON Sagres | 306 |


**7 rows**
## 💡 핵심 개념
`WHERE`는 그룹화하기 전의 개별 행을 필터링한다.
```sql
WHERE m.season = '2015/2016'
```
→ 2015/2016 시즌 경기만 남긴다.
`HAVING`은 `GROUP BY` 이후 만들어진 집계 결과를 필터링한다.
```sql
HAVING COUNT(*) >= 300
```
→ 리그별 경기 수가 300 이상인 그룹만 남긴다.
처리 흐름:
`WHERE → GROUP BY → HAVING`
---
# 문제 3 — 팀별 홈 경기 수와 홈 득점
## 문제
`team`과 `matches` 테이블에서 2015/2016 시즌 각 팀의 홈 경기 수와 홈 총득점을 조회한다.
홈 경기를 15경기 이상 치른 팀만 출력한다.
결과는 홈 총득점을 기준으로 내림차순 정렬하고, 홈 총득점이 같다면 팀 이름을 오름차순으로 정렬한다.
### 출력


| team_name | home_match_count | total_home_goals |
| --- | --- | --- |
| ... | ... | ... |


---
## ✅ 첫 시도 — 정답
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
## 📊 실제 결과
**188 rows**
상위 결과:


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


하위 결과 중:


| team_name | home_match_count | total_home_goals |
| --- | --- | --- |
| Aston Villa | 19 | 14 |
| Śląsk Wrocław | 15 | 14 |
| ES Troyes AC | 19 | 13 |
| SC Cambuur | 17 | 12 |
| Boavista FC | 17 | 10 |


## 💡 핵심 개념
```sql
COUNT(*)
```
→ 해당 팀의 홈 경기 횟수
```sql
SUM(m.home_team_goal)
```
→ 해당 팀이 홈 경기에서 기록한 총득점
문제에 **각 팀의** 홈 경기 수와 총득점이라는 표현이 있기 때문에 팀별 집계가 필요하다.
---
# 문제 4 — 홈팀이 3골 차 이상 승리한 경기
## 문제
`team`과 `matches` 테이블에서 2015/2016 시즌 경기 중 홈팀이 원정팀보다 최소 3골 이상 많이 득점한 경기를 조회한다.
### 출력


| match_date | home_team | away_team | home_goals | away_goals |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... |


결과는 홈팀과 원정팀의 골 차이가 큰 순서대로 정렬한다.
골 차이가 같다면 `match_date`를 기준으로 오름차순 정렬한다.
---
## ❌ 첫 시도
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
## 오류
### 1. 이름과 ID를 JOIN함
잘못된 구조:
```sql
t.team_long_name = m.home_team_api_id
```
`team_long_name`은 팀 이름이고 `home_team_api_id`는 팀의 ID다.
올바른 관계는:
```sql
m.home_team_api_id = h.team_api_id
m.away_team_api_id = a.team_api_id
```
이다.
### 2. 하나의 `team` alias로 홈팀과 원정팀을 모두 표현함
한 경기에는 서로 다른 홈팀과 원정팀이 존재한다.
따라서 동일한 `team` 테이블을 역할에 따라 두 번 JOIN해야 한다.
```sql
JOIN team h ...
JOIN team a ...
```
여기서:
- `h` = home team
- `a` = away team
### 3. alias 혼동
중간 과정에서 `h`, `a`를 선언하고 다시 존재하지 않는 `t`를 사용하는 오류가 발생했다.
alias를 만든 뒤에는 해당 역할을 끝까지 유지해야 한다.
### 4. 실제로 존재하지 않는 컬럼명을 사용함
중간 과정에서:
```sql
m.home_api_id
m.away_api_id
```
를 사용했다.
실제 컬럼명은:
```sql
m.home_team_api_id
m.away_team_api_id
```
이다.
### 5. 집계가 필요 없는 문제에 `SUM`, `GROUP BY`, `HAVING` 사용
이 문제는:
**팀별 총득점을 계산하는 문제**가 아니라
**조건을 만족하는 개별 경기를 조회하는 문제**다.
따라서 `SUM`, `GROUP BY`, `HAVING`이 필요하지 않다.
### 6. 테이블 역할 혼동
중간에 다음과 같은 형태의 오류가 있었다.
```sql
a.away_team_goal
```
하지만 `a`는 `team` 테이블이다.
득점 정보는 `matches`에 있기 때문에:
```sql
m.away_team_goal
```
을 사용해야 한다.
---
## ✅ 최종 쿼리
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
## 📊 실제 결과
**371 rows**
상위 결과:


| match_date | home_team | away_team | home_goals | away_goals |
| --- | --- | --- | --- | --- |
| 2015-12-20 | Real Madrid CF | Rayo Vallecano | 10 | 2 |
| 2016-01-19 | Celtic | Hamilton Academical FC | 8 | 1 |
| 2016-04-09 | BSC Young Boys | Lugano | 7 | 0 |
| 2016-05-15 | Celtic | Motherwell | 7 | 0 |


Real Madrid CF의 첫 경기 골 차이는:
`10 - 2 = 8`
Celtic의 다음 경기 골 차이는:
`8 - 1 = 7`
따라서 골 차이 내림차순 정렬이 실제 결과에서도 확인됐다.
## 💡 핵심 개념
같은 테이블이라도 서로 다른 역할을 표현해야 한다면 각각 별도의 alias를 사용한다.
```sql
JOIN team h
  ON m.home_team_api_id = h.team_api_id

JOIN team a
  ON m.away_team_api_id = a.team_api_id
```
역할:
- `m` → 경기 정보
- `h` → 홈팀 정보
- `a` → 원정팀 정보
따라서:
- 경기 날짜 → `m.match_date`
- 홈 득점 → `m.home_team_goal`
- 원정 득점 → `m.away_team_goal`
- 홈팀 이름 → `h.team_long_name`
- 원정팀 이름 → `a.team_long_name`
---
# 문제 5 — 팀별 원정 승리 횟수
## 문제
`team`과 `matches` 테이블에서 2015/2016 시즌 각 팀의 원정 승리 횟수를 조회한다.
원정팀의 득점이 홈팀의 득점보다 많으면 원정 승리로 계산한다.
원정 승리가 5회 이상인 팀만 출력한다.
결과는 원정 승리 횟수를 기준으로 내림차순 정렬하고, 원정 승리 횟수가 같다면 팀 이름을 오름차순으로 정렬한다.
### 출력


| team_name | away_win_count |
| --- | --- |
| ... | ... |


---
## ❌ 첫 시도
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
## 오류
### 1. 다시 ID와 팀 이름을 JOIN함
잘못된 JOIN:
```sql
m.away_team_api_id = a.team_long_name
```
올바른 JOIN:
```sql
m.away_team_api_id = a.team_api_id
```
### 2. 불필요한 홈팀 JOIN
문제에서 필요한 팀 정보는 원정팀 이름뿐이다.
따라서:
```sql
JOIN team h ...
```
는 필요하지 않다.
### 3. `GROUP BY` 누락
`COUNT(*)`를 전체가 아니라 **팀별로** 계산해야 한다.
따라서:
```sql
GROUP BY a.team_long_name
```
이 필요하다.
### 4. 컬럼명 오타
중간 시도:
```sql
GROUP BY a.team._long_name
```
실제 컬럼명:
```sql
a.team_long_name
```
### 5. `HAVING` 누락
문제의 조건은:
**원정 승리가 5회 이상인 팀**
이다.
원정 승리 횟수는 `COUNT(*)`를 통해 그룹화 이후 계산되므로:
```sql
HAVING COUNT(*) >= 5
```
를 사용한다.
### 6. `ORDER BY` 기준 오류
초기에는:
```sql
ORDER BY (away_team_goal > home_team_goal) DESC
```
를 사용했다.
하지만 이미 `WHERE`에서:
```sql
m.away_team_goal > m.home_team_goal
```
인 경기만 남겼다.
따라서 남아 있는 경기에서는 해당 조건이 모두 참이므로 정렬 기준으로 의미가 없다.
문제에서 원하는 정렬 기준은 팀별 원정 승리 횟수이므로:
```sql
ORDER BY away_win_count DESC
```
를 사용한다.
### 7. 불필요한 `LIMIT`
문제에서는 상위 10개 팀만 출력하라고 요구하지 않았다.
따라서:
```sql
LIMIT 10
```
을 사용하면 정답 결과와 행 수가 달라진다.
---
## ✅ 최종 쿼리
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
## 📊 실제 결과
**109 rows in set (0.03 sec)**
상위 결과:


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


이후 9승, 8승, 7승, 6승, 5승 순으로 정상적으로 정렬됐으며 최종적으로 원정 5승 이상인 팀이 109개 조회됐다.
## 💡 핵심 개념
이 문제의 처리 흐름:
`WHERE → GROUP BY → COUNT → HAVING → ORDER BY`
구체적으로 보면:
1. `WHERE`
- 2015/2016 시즌만 선택
- 원정 승리 경기만 선택
2. `GROUP BY`
- 원정팀별로 경기들을 묶음
3. `COUNT(*)`
- 각 팀의 원정 승리 경기 수 계산
4. `HAVING`
- 원정 승리가 5회 이상인 팀만 선택
5. `ORDER BY`
- 원정 승리 횟수 내림차순
- 동률이면 팀 이름 오름차순
---
# 🔎 Day 4 주요 오답 패턴
## 1. JOIN 문법 자체보다 JOIN 키 선택에서 반복 오류
오늘 가장 반복된 오류는 다음 형태였다.
`api id ↔ 팀 이름`
예:
```sql
m.away_team_api_id = a.team_long_name
```
하지만 JOIN은 두 컬럼이 의미상 같은 값을 나타내야 한다.
이번 데이터의 핵심 관계는 다음과 같다.
```plain text
matches.league_id        ↔ league.id
matches.home_team_api_id ↔ team.team_api_id
matches.away_team_api_id ↔ team.team_api_id
```
따라서 앞으로 JOIN을 작성할 때는 우선:
**이 두 컬럼이 정말 같은 종류의 ID인가?**
를 확인한다.
---
## 2. 긴 쿼리에서 alias 역할이 섞이는 문제가 있음
P4에서:
```sql
matches m
team h
team a
```
를 사용했지만 중간에 `t`를 다시 사용하거나 `team` 테이블에서 경기 득점 컬럼을 찾는 오류가 발생했다.
JOIN 전에 역할을 짧게 정리하면 도움이 된다.
```plain text
m = match
h = home team
a = away team
```
그리고 컬럼을 찾을 때:
```plain text
경기 날짜 → m
득점 → m
시즌 → m

홈팀 이름 → h
원정팀 이름 → a
```
로 구분한다.
---
## 3. 개별 행 조회와 집계 문제를 먼저 구분해야 함
### P4
문제:
**3골 차 이상으로 승리한 경기**
원하는 결과의 한 행:
**한 경기**
따라서 개별 경기 조회 문제다.
`SUM`, `GROUP BY`, `HAVING`이 필요하지 않다.
### P5
문제:
**팀별 원정 승리 횟수**
원하는 결과의 한 행:
**한 팀**
여러 경기 데이터를 한 팀으로 묶어야 한다.
따라서:
```sql
GROUP BY
COUNT(*)
```
가 필요하다.
문제를 읽은 뒤 가장 먼저 생각할 것:
> 최종 결과의 한 행은 무엇을 의미하는가?
이 질문으로 집계 여부를 먼저 판단한다.
---
## 4. `WHERE`와 `HAVING` 구분은 이전보다 안정적
P2에서는 첫 시도부터:
```sql
WHERE m.season = '2015/2016'
GROUP BY l.name
HAVING COUNT(*) >= 300
```
을 정확하게 작성했다.
P5에서도 `COUNT(*) >= 5`가 집계 결과 조건이라는 점을 확인한 뒤:
```sql
HAVING COUNT(*) >= 5
```
를 적용했다.
따라서 현재 우선적으로 보완할 부분은 `WHERE`와 `HAVING`보다는:
- JOIN 키 선택
- alias 관리
- 실제 컬럼명 확인
- 전체 SQL 조립
쪽이다.
---
## 5. `ORDER BY`에서는 무엇을 정렬해야 하는지 먼저 판단
P4에서는 골 차이를 정렬해야 했다.
```sql
ORDER BY (m.home_team_goal - m.away_team_goal) DESC
```
P5에서는 팀별 원정 승리 횟수를 정렬해야 했다.
```sql
ORDER BY away_win_count DESC
```
따라서 문제의 조건에 나온 표현을 그대로 `ORDER BY`에 넣는 것이 아니라:
> 최종 결과에서 어떤 값을 기준으로 순서를 정해야 하는가?
를 먼저 판단한다.
---
# 📝 오늘의 회고
오늘 P1\~P3는 비교적 안정적으로 해결했다.
특히 P2와 P3는 첫 시도에 정답을 작성했기 때문에 다음 기본 흐름은 어느 정도 자리 잡고 있다.
```plain text
JOIN
→ WHERE
→ GROUP BY
→ HAVING
→ ORDER BY
```
반면 P4에서 같은 `team` 테이블을 홈팀과 원정팀 역할로 두 번 JOIN하면서 오류가 크게 증가했다.
가장 큰 문제는 JOIN이라는 개념 자체를 모르는 것보다는 다음 네 가지였다.
1. 실제 컬럼명을 정확하게 기억해서 작성하기
2. 여러 alias의 역할을 끝까지 유지하기
3. JOIN에서 ID와 이름 중 어떤 컬럼을 연결해야 하는지 판단하기
4. 여러 조건을 하나의 긴 SQL로 조립하기
특히 P4에서:
```sql
JOIN team h
  ON m.home_team_api_id = h.team_api_id

JOIN team a
  ON m.away_team_api_id = a.team_api_id
```
라는 구조를 이해한 뒤에도 컬럼명이나 alias가 반복해서 섞였다.
P5에서도 첫 시도에서 다시:
```sql
m.away_team_api_id = a.team_long_name
```
으로 작성했기 때문에 **JOIN 키 선택은 아직 반복 연습이 필요하다.**
다만 P4 후반에는 홈팀과 원정팀을 각각 `h`, `a`로 JOIN하는 구조를 직접 완성했고, P5에서는 최종적으로 불필요한 홈팀 JOIN 없이:
```sql
JOIN team a
  ON m.away_team_api_id = a.team_api_id
```
만 사용하는 구조까지 완성했다.
따라서 지금 단계에서는 새로운 고급 문법을 빠르게 추가하기보다 **JOIN + GROUP BY가 함께 등장하는 문제에서 전체 쿼리를 안정적으로 작성하는 연습**을 조금 더 하는 것이 필요하다.
---
# ➡️ 다음 학습 포인트
다음 Sports SQL에서는 문제를 읽은 뒤 다음 순서로 판단한다.
```plain text
1. 최종 결과의 한 행은 무엇인가?
   ↓
   경기인가? 팀인가? 리그인가?

2. 기준 테이블은 무엇인가?
   ↓
   matches? team? league?

3. 다른 테이블에서 어떤 정보가 필요한가?
   ↓
   팀 이름? 리그 이름?

4. JOIN 키는 무엇인가?
   ↓
   ID ↔ ID인지 확인

5. 개별 행 조회인가, 집계 문제인가?
   ↓
   집계라면 GROUP BY 필요

6. 개별 행 조건인가?
   ↓
   WHERE

7. 집계 결과 조건인가?
   ↓
   HAVING

8. 무엇을 기준으로 정렬해야 하는가?
   ↓
   ORDER BY
```
다음 Sports 학습에서는 이 흐름을 다시 적용하면서 JOIN을 안정화하고, 이후 `CASE`와 window function으로 확장한다.

---
