# Day 02 — 학습 원기록

[English](../en/day02.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### ⚽ Day2 — WHERE·GROUP BY·시즌별 집계
# `SQL` 학습 기록 — `WHERE`와 `GROUP BY` 구분 및 시즌별 집계
## 1. 데이터셋
이번 학습에서는 Kaggle의 European Soccer Database를 사용했다.
- Dataset: European Soccer Database
- Source: Kaggle
- Creator: Hugo Mathien
- Database: MySQL 8.4
- 사용 테이블: `Match`
- 전체 경기 수: 25,979경기
이번 세션에서 주로 사용한 컬럼:
- `season`: 시즌
- `home_team_goal`: 홈팀 득점
- `away_team_goal`: 원정팀 득점
---
## 1. 이번 세션 목표
이전 세션에서 복습한 `WHERE`, 집계 함수, `GROUP BY`, `ORDER BY`를 결합하여 직접 쿼리를 작성하는 연습을 진행했다.
특히 이번에는 다음 차이를 명확하게 구분하는 것을 주요 목표로 했다.
`WHERE` = 계산에 사용할 행을 먼저 필터링
`GROUP BY` = 남은 데이터를 특정 기준으로 그룹화
또한 분석 질문을 읽은 뒤 다음 구조를 스스로 판단하는 연습을 했다.
`SELECT`
→ `FROM`
→ `WHERE` (필요한 경우)
→ `GROUP BY`
→ `ORDER BY`
---
### 문제 11. 특정 시즌 이후의 시즌별 평균 원정 득점
#### 문제
`Match` 테이블에서 2013/2014 시즌 이후 경기만 대상으로 시즌별 평균 원정 득점을 계산한다.
출력 컬럼:
`season`
`avg_away_goals`
결과는 시즌 오름차순으로 정렬한다.
---
#### 첫 번째 작성 쿼리
```sql
SELECT
season,
AVG(away_goals) AS (avg_away_goals)
FROM `Match`
GROUP BY season > '2013/2014'
ORDER BY avg_away_goals DESC
LIMIT 10;
```
#### 문제점
여러 가지 문제가 있었다.
## 1. away_goals라는 컬럼은 존재하지 않고 실제 컬럼명은 `away_team_goal`이다.
## 2. 별칭에 `AS` (`avg_away_goals`)처럼 괄호를 사용할 필요가 없다.
## 3. 시즌 조건을 `GROUP BY` 안에 작성했다.
## 4. 문제는 시즌 오름차순인데 평균값 내림차순으로 정렬했다.
## 5. `LIMIT` 10은 필요하지 않았다.
---
#### 두 번째 실행 쿼리
```sql
SELECT
season,
AVG(away_team_goal) AS avg_away_goals
FROM `Match`
GROUP BY season >= '2013/2014'
ORDER BY avg_away_goals;
```
#### 실행 결과


| `season` | `avg_away_goals` |
| --- | --- |
| 2008/2009 | 1.14684585174276 |
| 2013/2014 | 1.18465351647217 |


이 결과가 두 행만 나온 이유는
`GROUP BY` `season` \>= '2013/2014'
가 시즌별 그룹화를 의미하지 않기 때문이다.
`season` \>= '2013/2014'는 조건식의 0/1 결과를 그룹 기준으로 사용하므로 시즌별 그룹화가 아니다. MySQL 8.x에서는 `SELECT season`이 그룹 기준에 없어 기본 `ONLY_FULL_GROUP_BY`에서 오류가 발생할 수 있다.
즉,
FALSE 그룹
TRUE 그룹
두 그룹으로만 집계된 것이다.
---
#### MySQL 8.x 기준 정답
```sql
SELECT
season,
AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2013/2014'
GROUP BY season
ORDER BY season ASC;
```
#### 실제 결과


| `season` | `avg_away_goals` |
| --- | --- |
| 2013/2014 | 1.18799472295515 |
| 2014/2015 | 1.15548872180451 |
| 2015/2016 | 1.21076368009621 |


#### 핵심 학습
이번 문제에서 가장 중요한 부분은 `WHERE`와 `GROUP BY`의 역할 구분이었다.
`WHERE` `season` \>= '2013/2014'
먼저 2013/2014 시즌 이후 경기만 남긴다.
그 다음
`GROUP BY` `season`
으로 남은 경기들을 시즌별로 나눈다.
따라서 처리 흐름은 다음과 같다.
전체 경기
→ 2013/2014 이후 경기 필터링
→ 시즌별 그룹화
→ 시즌별 평균 원정 득점 계산
---
### 문제 12. 시즌별 평균 총 득점
#### 문제
`Match` 테이블에서 시즌별 평균 총 득점을 계산한다.
한 경기의 총 득점은 다음과 같다.
`home_team_goal` + `away_team_goal`
출력 컬럼:
`season`
avg_total_goals
평균 총 득점이 높은 시즌부터 정렬한다.
---
#### 첫 번째 작성 쿼리
```sql
SELECT
season,
AVG(home_team_goal + away_team_goal) AS avg_total_goals
FROM `Match`
WHERE season
ORDER BY avg_total_goals;
```
#### 실행 결과


| `season` | `avg_total_goals` |
| --- | --- |
| 2008/2009 | 2.70553139073867 |


---
#### 문제점
평균을 계산하는 식 자체는 맞았다.
`AVG`(`home_team_goal` + `away_team_goal`)
하지만 두 가지 핵심 문제가 있었다.
## 1. `WHERE` `season`
`WHERE` `season`
은 이번 문제에서 필요한 필터 조건이 아니다. MySQL에서도 문자열을 논리값으로 암묵 변환하게 되므로 이런 조건에 의존하면 안 된다.
특정 시즌을 선택하라는 조건이 없기 때문이다.
## 1. `GROUP BY` `season` 누락
시즌별 평균을 구하려면 반드시 시즌을 기준으로 그룹화해야 한다.
`GROUP BY` 없이 집계 함수를 사용했기 때문에 전체 데이터를 하나의 집계 그룹으로 계산했다.
그 상태에서 `season`까지 `SELECT`하면 MySQL 8.x의 기본 `ONLY_FULL_GROUP_BY` 규칙에 위배되어 오류가 발생한다.
---
#### MySQL 8.x 기준 정답
```sql
SELECT
season,
AVG(home_team_goal + away_team_goal) AS avg_total_goals
FROM `Match`
GROUP BY season
ORDER BY avg_total_goals DESC;
```
#### 실제 결과


| `season` | `avg_total_goals` |
| --- | --- |
| 2012/2013 | 2.77269938650307 |
| 2013/2014 | 2.76682058047493 |
| 2015/2016 | 2.75466025255562 |
| 2011/2012 | 2.71645962732919 |
| 2010/2011 | 2.68374233128834 |
| 2014/2015 | 2.67578947368421 |
| 2009/2010 | 2.67244582043344 |
| 2008/2009 | 2.60733613950692 |


#### 핵심 학습
특정 행을 제거할 조건이 없다면 `WHERE`를 억지로 사용할 필요가 없다.
이번 문제에서는
시즌별
이라는 표현 때문에 `GROUP BY` `season`이 필요하다.
반면 특정 시즌만 분석한다는 조건은 없으므로 `WHERE`는 필요하지 않다.
---
### 문제 13. 시즌별 홈팀 3골 이상 경기 수
#### 문제
`Match` 테이블에서 시즌별 홈팀이 3골 이상 기록한 경기 수를 계산한다.
출력 컬럼:
`season`
`high_scoring_home_matches`
경기 수가 많은 시즌부터 정렬한다.
---
#### 첫 번째 작성 쿼리
```sql
SELECT
season,
COUNT(*) AS high_scoring_home_matches
FROM `Match`
WHERE high_scoring_home_matchesl >= 3;
```
오류
Parse error: no such column: high_scoring_home_matchesl
`high_scoring_home_matches`는 결과에 붙이는 별칭이고 원본 데이터 컬럼이 아니다.
조건을 걸어야 하는 대상은 실제 홈팀 득점 컬럼이다.
---
두 번째 작성 쿼리
```sql
SELECT
season,
COUNT(*) AS high_scoring_home_matches
FROM `Match`
WHERE home_goal >= 3
GROUP BY season
ORDER BY high_scoring_home_matches DESC;
```
이번에는 `SQL` 구조는 맞았지만 컬럼명을 잘못 기억했다.
home_goal
이 아니라 실제 컬럼명은
`home_team_goal`
이다.
---
#### MySQL 8.x 기준 정답
```sql
SELECT
season,
COUNT(*) AS high_scoring_home_matches
FROM `Match`
WHERE home_team_goal >= 3
GROUP BY season
ORDER BY high_scoring_home_matches DESC;
```
#### 실제 결과


| `season` | `high_scoring_home_matches` |
| --- | --- |
| 2011/2012 | 703 |
| 2015/2016 | 685 |
| 2012/2013 | 673 |
| 2013/2014 | 664 |
| 2014/2015 | 663 |
| 2010/2011 | 656 |
| 2009/2010 | 655 |
| 2008/2009 | 645 |


#### 핵심 학습
이번 문제에서는 `SQL` 구조 자체는 두 번째 시도에서 정확하게 작성했다.
처리 흐름은 다음과 같다.
홈팀 3골 이상 경기만 선택
→ 시즌별 그룹화
→ 각 시즌의 경기 수 계산
→ 경기 수 기준 내림차순 정렬
즉,
`WHERE` `home_team_goal` \>= 3
으로 분석 대상을 먼저 제한하고,
`GROUP BY` `season`
으로 시즌별로 묶은 뒤,
`COUNT`(\*)
로 각 시즌의 경기 수를 계산한다.
---
### 문제 14. 시즌별 원정 승리 경기 수
#### 문제
`Match` 테이블에서 시즌별 원정팀 승리 경기 수를 계산한다.
원정 승리 조건:
`away_team_goal` \> `home_team_goal`
출력 컬럼:
`season`
`away_win_matches`
원정 승리 경기 수가 많은 시즌부터 정렬한다.
---
작성한 쿼리
```sql
SELECT
season,
COUNT(*) AS away_win_matches
FROM `Match`
WHERE away_team_goal > home_team_goal
GROUP BY season
ORDER BY away_win_matches DESC;
```
#### 실제 결과


| `season` | `away_win_matches` |
| --- | --- |
| 2015/2016 | 1012 |
| 2014/2015 | 981 |
| 2012/2013 | 963 |
| 2008/2009 | 929 |
| 2011/2012 | 904 |
| 2010/2011 | 901 |
| 2013/2014 | 892 |
| 2009/2010 | 884 |


#### 핵심 학습
이번 문제에서는 처음부터 `SQL` 구조를 정확하게 작성했다.
`WHERE` `away_team_goal` \> `home_team_goal`
을 이용해 원정팀이 승리한 경기만 선택한 뒤,
`GROUP BY` `season`
으로 시즌별 그룹을 만들고,
`COUNT`(\*)
으로 시즌별 원정 승리 경기 수를 계산했다.
---
### 문제 15. 시즌별 무승부 경기 수
#### 문제
`Match` 테이블에서 시즌별 무승부 경기 수를 계산한다.
무승부 조건:
`home_team_goal` = `away_team_goal`
출력 컬럼:
`season`
`draw_matches`
무승부 경기 수가 많은 시즌부터 정렬한다.
---
작성한 쿼리
```sql
SELECT
season,
COUNT(*) draw_matches
FROM `Match`
WHERE home_team_goal = away_team_goal
GROUP BY season
ORDER BY draw_matches DESC;
```
#### 실제 결과


| `season` | `draw_matches` |
| --- | --- |
| 2015/2016 | 855 |
| 2012/2013 | 853 |
| 2014/2015 | 850 |
| 2010/2011 | 839 |
| 2008/2009 | 831 |
| 2011/2012 | 818 |
| 2009/2010 | 814 |
| 2013/2014 | 736 |


#### 핵심 학습
이번 문제도 처음 작성한 구조가 정확했다.
또한 MySQL에서도 다음처럼 `AS`를 생략해 별칭을 사용할 수 있다.
`COUNT`(\*) `draw_matches`
이는 다음과 동일하다.
`COUNT`(\*) `AS` `draw_matches`
가독성을 위해서는 `AS`를 사용하는 방법도 좋다.
---
## 1. 오늘의 핵심 정리
`WHERE`와 `GROUP BY`
이번 세션에서 가장 중요했던 부분은 `WHERE`와 `GROUP BY`를 분리해서 이해하는 것이었다.
`WHERE`
특정 조건을 만족하는 행을 먼저 선택한다.
`WHERE` `home_team_goal` \>= 3
예를 들어 전체 경기 중 홈팀이 3골 이상 기록한 경기만 남긴다.
---
`GROUP BY`
남아 있는 행을 특정 기준으로 그룹화한다.
`GROUP BY` `season`
즉, 같은 시즌의 경기끼리 묶는다.
---
두 구문의 처리 관계
예를 들어:
`WHERE` `away_team_goal` \> `home_team_goal`
`GROUP BY` `season`
은 다음 순서로 이해할 수 있다.
전체 경기
↓
원정 승리 경기만 선택
↓
시즌별로 그룹화
↓
각 시즌의 원정 승리 수 계산
---
## 1. 이번 세션에서 나온 주요 실수
## 2. 조건식을 `GROUP BY`에 작성
잘못된 예:
`GROUP BY` `season` \>= '2013/2014'
이 표현은 2013/2014 이후 데이터를 선택하는 것이 아니라 조건식의 참/거짓 결과를 기준으로 그룹화한다.
올바른 구조:
`WHERE` `season` \>= '2013/2014'
`GROUP BY` `season`
---
## 1. 필요하지 않은 `WHERE` 사용
잘못된 예:
`WHERE` `season`
분석 질문에 특정 행을 제한하는 조건이 없다면 `WHERE`가 필요하지 않을 수 있다.
예를 들어:
시즌별 평균 총 득점
에서는 모든 시즌을 분석해야 하기 때문에 별도의 `WHERE` 조건이 필요하지 않다.
---
## 1. `GROUP BY` 누락
집계 함수를 사용하더라도
`AVG`(...)
만 작성하면 전체 데이터에 대한 하나의 평균이 계산된다.
시즌별 평균이 필요하다면:
`GROUP BY` `season`
을 추가해야 한다.
---
## 1. 원본 컬럼과 별칭 혼동
다음과 같은 별칭은:
`COUNT`(\*) `AS` `high_scoring_home_matches`
계산 결과에 붙인 이름이다.
원본 `Match` 테이블에 `high_scoring_home_matches`라는 컬럼이 생성되는 것은 아니다.
따라서 원본 데이터를 필터링할 때는 실제 컬럼을 사용해야 한다.
`WHERE` `home_team_goal` \>= 3
---
## 1. 오늘의 `SQL` 사고 순서
문제를 읽은 뒤 바로 코드를 작성하기보다 다음 순서로 생각하는 것이 도움이 됐다.
## 1. 무엇을 출력하는가?
`SELECT`
## 1. 어느 테이블에서 가져오는가?
`FROM`
## 1. 일부 행만 필요한가?
필요하다면:
`WHERE`
필요하지 않으면 생략한다.
## 1. 무엇을 기준으로 나눠야 하는가?
예:
시즌별
리그별
팀별
이런 표현이 나오면 `GROUP BY`가 필요한지 판단한다.
## 1. 어떤 계산을 해야 하는가?
`COUNT`
`AVG`
`SUM`
## 1. 어떤 순서로 결과를 보여주는가?
`ORDER BY`
---
## 1. 오늘의 회고
이번 세션에서는 문제 11부터 문제 15까지 총 5문제를 풀었다.
초반에는 `WHERE`와 `GROUP BY`의 역할을 혼동해 필터 조건을 `GROUP BY`에 넣거나, 필터링이 필요하지 않은 문제에 `WHERE`를 작성하는 실수가 있었다.
특히 다음 쿼리를 실행하면서:
`GROUP BY` `season` \>= '2013/2014'
조건식을 그룹화 기준으로 넣으면 시즌별 결과가 아니라 참/거짓 기준의 그룹이 만들어질 수 있다는 점을 실제 결과를 통해 확인했다.
문제 12에서도 `GROUP BY` `season`이 없으면 시즌별 평균이 아니라 전체 데이터의 하나의 평균이 계산된다는 점을 다시 확인했다.
이후 문제 13에서는 컬럼명을 잘못 기억하는 실수는 있었지만 `SQL`의 구조 자체는 올바르게 작성했고, 문제 14와 문제 15에서는 처음부터 `WHERE` → `GROUP BY` → `COUNT` → `ORDER BY` 구조를 직접 작성했다.
이번 세션에서 가장 중요했던 학습 내용은 `SQL` 문법 자체보다 다음 질문을 먼저 판단하는 것이었다.
이 문제는 데이터를 필터링해야 하는가?
이 문제는 데이터를 그룹으로 나눠야 하는가?
`WHERE`와 `GROUP BY`의 차이를 실제 문제와 실행 결과를 통해 반복적으로 확인한 세션이었다.
---
## 1. 다음 학습 계획
다음 세션에서는 지금까지 복습한
`WHERE`
`GROUP BY`
`COUNT`
`AVG`
`SUM`
`ORDER BY`
를 조금 더 결합한 뒤 `HAVING`으로 넘어간다.
다음 학습 흐름:
`GROUP BY` 복합 문제
→ `HAVING`
→ `JOIN` 복습
→ CASE WHEN
→ Window Function
이후 Window Function에서는 다음 내용을 학습할 예정이다.
`ROW_NUMBER()`
RANK()
`DENSE_RANK()`
`PARTITION BY`
`LAG()`
`LEAD()`
`SUM()` OVER()
`AVG()` OVER()
최종 목표는 `SQL` 문법을 단순 암기하는 것이 아니라, 분석 질문을 읽고 필요한 `SQL` 구조를 스스로 결정하고 결과가 논리적으로 맞는지도 검증할 수 있도록 하는 것이다.
