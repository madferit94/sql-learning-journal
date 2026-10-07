# Day 03 — 학습 원기록

[English](../en/day03.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### ⚽ Day3 — HAVING·집계 결과 필터링
# `SQL` 학습 기록 — `HAVING`과 `WHERE`/`GROUP BY` 구분
## 1. 학습 정보
- Dataset: European Soccer Database
- Database: MySQL 8.4
- Main Table: `Match`
- 전체 `Match` 행 수: 25,979
- 학습 범위: 문제 16\~20
- 핵심 주제: `WHERE`, `GROUP BY`, `HAVING`, `COUNT`, `AVG`, `SUM`, `ORDER BY`
- 오늘의 핵심 목표: 원본 행에 대한 조건과 집계 결과에 대한 조건을 구분하고, 여러 집계 함수를 하나의 쿼리에서 사용하는 연습
---
### 문제 16 — `WHERE` + `GROUP BY` 복습
#### 문제
`Match` 테이블에서 2010/2011 시즌 이후 경기만 대상으로 시즌별 평균 홈팀 득점을 구한다.
출력:
- `season`
- `avg_home_goals`
평균 홈 득점이 높은 시즌부터 정렬한다.
첫 번째 시도
```sql
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
WHERE season > '2013/2014'
GROUP BY season
ORDER BY season;
```
#### 실행 결과


| `season` | `avg_home_goals` |
| --- | --- |
| 2014/2015 | 1.5203007518797 |
| 2015/2016 | 1.54389657245941 |


#### 문제점
`SQL`의 기본 구조 자체는 맞았다.
하지만 문제의 조건을 정확하게 옮기지 못했다.
## 1. 문제는 2010/2011 이후였지만 2013/2014를 입력했다.
## 2. 2010/2011 시즌도 포함해야 하므로 \>가 아니라 \>=가 필요했다.
## 3. 평균 홈 득점이 높은 순으로 정렬해야 하는데 `season`으로 정렬했다.
---
#### 두 번째 시도
```sql
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
WHERE season > '2010/2011'
GROUP BY season
ORDER BY avg_home_goals;
```
#### 실행 결과


| `season` | `avg_home_goals` |
| --- | --- |
| 2014/2015 | 1.5203007518797 |
| 2015/2016 | 1.54389657245941 |
| 2012/2013 | 1.55 |
| 2011/2012 | 1.57267080745342 |
| 2013/2014 | 1.57882585751979 |


#### 문제점
이번에는 기준 시즌은 수정했지만:
- 때문에 2010/2011이 제외됨
- `ORDER BY` `avg_home_goals`는 기본값이 `ASC`이므로 낮은 평균부터 정렬됨
---
#### MySQL 8.x 기준 최종 정답
```sql
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
ORDER BY avg_home_goals DESC;
```
#### 실제 결과


| `season` | `avg_home_goals` |
| --- | --- |
| 2013/2014 | 1.57882585751979 |
| 2011/2012 | 1.57267080745342 |
| 2012/2013 | 1.55 |
| 2010/2011 | 1.54846625766871 |
| 2015/2016 | 1.54389657245941 |
| 2014/2015 | 1.5203007518797 |


#### 핵심 개념
> = 초과
=  = 이상(기준값 포함)
`ASC`  = 작은 값 → 큰 값
`DESC` = 큰 값 → 작은 값
이번 오류는 `WHERE`와 `GROUP BY` 자체를 잘못 이해했다기보다는 문제 조건을 `SQL`로 정확하게 옮기는 과정의 오류였다.
---
### 문제 17 — `HAVING` 첫 연습
#### 문제
시즌별 경기 수를 계산하고, 경기 수가 3,250경기 이상인 시즌만 출력한다.
출력:
- `season`
- `match_count`
경기 수가 많은 시즌부터 정렬한다.
---
첫 번째 시도
```sql
SELECT season, COUNT(**) AS match_count*
*FROM `Match`*
*HAVING COUNT(**) >= 3250;
```
#### 실제 결과


| `season` | `match_count` |
| --- | --- |
| 2008/2009 | 25979 |


#### 문제점
`GROUP BY` `season`이 없었다.
따라서 시즌별로 계산하지 않고 전체 `Match` 테이블 25,979행을 하나의 집계 대상으로 계산했다.
`season`이 2008/2009로 표시됐지만 이것이 2008/2009 시즌의 경기 수라는 뜻은 아니다.
핵심
문제에 **“시즌별”**이라는 표현이 있다면 어떤 컬럼을 기준으로 그룹화할 것인지 확인해야 한다.
---
#### 두 번째 시도
```sql
SELECT season, COUNT(**) AS match_count
FROM `Match`
GROUP BY season
HAVING COUNT(\**)
ORDER BY season DESC;
```
#### 실제 결과


| `season` | `match_count` |
| --- | --- |
| 2015/2016 | 3326 |
| 2014/2015 | 3325 |
| 2013/2014 | 3032 |
| 2012/2013 | 3260 |
| 2011/2012 | 3220 |
| 2010/2011 | 3260 |
| 2009/2010 | 3230 |
| 2008/2009 | 3326 |


#### 문제점
`GROUP BY` `season`은 추가했지만:
`HAVING` `COUNT`(\*)
에서 비교 조건을 끝까지 작성하지 않았다.
---
#### 세 번째 시도
```sql
SELECT season, COUNT(**) AS match_count
FROM `Match`
GROUP BY season
HAVING COUNT(\**) >= 3250
ORDER BY season DESC;
```
#### 실제 결과


| `season` | `match_count` |
| --- | --- |
| 2015/2016 | 3326 |
| 2014/2015 | 3325 |
| 2012/2013 | 3260 |
| 2010/2011 | 3260 |
| 2008/2009 | 3326 |


#### 문제점
`HAVING` 조건은 성공했다.
하지만 문제에서는 경기 수가 많은 순으로 정렬하라고 했는데 `season` `DESC`로 정렬했다.
---
#### MySQL 8.x 기준 최종 정답
```sql
SELECT season, COUNT(*) AS match_count
FROM `Match`
GROUP BY season
HAVING COUNT(*) >= 3250
ORDER BY match_count DESC;
```
#### 실제 결과


| `season` | `match_count` |
| --- | --- |
| 2015/2016 | 3326 |
| 2008/2009 | 3326 |
| 2014/2015 | 3325 |
| 2012/2013 | 3260 |
| 2010/2011 | 3260 |


#### 핵심 개념
`HAVING`은 `GROUP BY`를 통해 만들어진 그룹의 집계 결과에 조건을 적용한다.
`GROUP BY` `season`
↓
시즌별 그룹 생성
↓
`COUNT()` 계산
↓
`HAVING` `COUNT`(\*\*) \>= 3250
↓
조건을 만족하는 시즌만 남김
---
### 문제 18 — `WHERE`와 `HAVING` 구분
#### 문제
2012/2013 시즌 이후 경기만 대상으로 시즌별 평균 원정팀 득점을 계산한다.
그중 평균 원정 득점이 1.18 이상인 시즌만 출력한다.
출력:
- `season`
- `avg_away_goals`
평균 원정 득점이 높은 시즌부터 정렬한다.
---
첫 번째 시도
```sql
SELECT season, AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2012/2013'
HAVING avg_away_goals >= 1.18
ORDER BY avg_away_goals DESC;
```
#### 실제 결과


| `season` | `avg_away_goals` |
| --- | --- |
| 2012/2013 | 1.19423626670787 |


#### 문제점
`WHERE`는 제대로 사용했지만 `GROUP BY` `season`이 없었다.
따라서 2012/2013 이후의 경기 전체를 하나로 묶어서 평균을 계산했다.
결과에 2012/2013이 표시됐다고 해서 이것이 2012/2013 시즌의 평균이라는 뜻은 아니다.
---
#### 두 번째 시도
```sql
SELECT season, AVG(away_team_goal) AS avg_away_goals
FROM `Match`
GROUP BY season >= '2012/2013'
HAVING avg_away_goals >= 1.18
ORDER BY avg_away_goals DESC;
```
#### 실제 결과


| `season` | `avg_away_goals` |
| --- | --- |
| 2012/2013 | 1.19423626670787 |


개념 오류
`GROUP BY` `season` \>= '2012/2013'
은 시즌별 그룹화를 의미하지 않는다.
`season` \>= '2012/2013'이라는 조건식의 결과를 기준으로 그룹화하게 된다.
즉 개념적으로:
조건이 거짓 → 0
조건이 참 → 1
처럼 그룹이 만들어질 수 있다.
조건은 `WHERE`, 그룹 기준은 `GROUP BY`에 넣어야 한다.
---
#### 세 번째 시도
같은 `GROUP BY` `season` \>= '2012/2013' 오류가 한 번 더 반복됐다.
이 과정에서 다시 다음 구조를 확인했다.
2012/2013 이후 경기만 선택
→ `WHERE`
시즌별로 묶기
→ `GROUP BY` `season`
평균이 1.18 이상인 그룹만 선택
→ `HAVING`
---
#### MySQL 8.x 기준 최종 정답
```sql
SELECT season, AVG(away_team_goal) AS avg_away_goals
FROM `Match`
WHERE season >= '2012/2013'
GROUP BY season
HAVING avg_away_goals >= 1.18
ORDER BY avg_away_goals DESC;
```
#### 실제 결과


| `season` | `avg_away_goals` |
| --- | --- |
| 2012/2013 | 1.22269938650307 |
| 2015/2016 | 1.21076368009621 |
| 2013/2014 | 1.18799472295515 |


#### 핵심 개념
이번 문제에서 두 조건은 성격이 다르다.
`season` \>= '2012/2013'
→ 원본 경기 행에 적용
→ `WHERE`
`AVG`(`away_team_goal`) \>= 1.18
→ 시즌별 평균을 계산한 이후 적용
→ `HAVING`
---
### 문제 19 — `WHERE` + `GROUP BY` + `HAVING` + `SUM`
#### 문제
2011/2012 시즌 이후 경기만 대상으로 시즌별 전체 득점 합계를 계산한다.
전체 득점:
`home_team_goal` + `away_team_goal`
단, 시즌 전체 득점이 8,800골 이상인 시즌만 출력한다.
출력:
- `season`
- `total_goals`
전체 득점이 높은 시즌부터 정렬한다.
---
첫 번째 시도 — 정답
```sql
SELECT season, SUM(home_team_goal + away_team_goal) AS total_goals
FROM `Match`
WHERE season >= '2011/2012'
GROUP BY season
HAVING total_goals >= 8800
ORDER BY total_goals DESC;
```
#### 실제 결과


| `season` | `total_goals` |
| --- | --- |
| 2015/2016 | 9162 |
| 2012/2013 | 9039 |
| 2014/2015 | 8897 |


잘한 점
문제 18에서 반복됐던:
`GROUP BY` `season` \>= ...
오류를 반복하지 않았다.
이번에는 처음부터:
`WHERE`
→ 원본 행 필터링
`GROUP BY`
→ 시즌별 그룹화
`SUM`
→ 시즌별 집계
`HAVING`
→ 집계 결과 필터링
`ORDER BY`
→ 결과 정렬
순서를 정확하게 구성했다.
---
### 문제 20 — 오늘의 종합 문제
#### 문제
2010/2011 시즌 이후 경기만 대상으로 시즌별로 다음 세 가지 지표를 동시에 계산한다.
- 전체 경기 수 → `match_count`
- 평균 홈팀 득점 → `avg_home_goals`
- 전체 득점 합계 → `total_goals`
단, 시즌별 경기 수가 3,250경기 이상인 시즌만 출력한다.
출력:
- `season`
- `match_count`
- `avg_home_goals`
- `total_goals`
전체 득점이 높은 시즌부터 정렬한다.
---
첫 번째 접근
처음에는 하나의 쿼리에서 세 지표를 계산하지 않고 각각 따로 계산했다.
경기 수
```sql
SELECT season, COUNT(*) AS match_count
FROM `Match`
GROUP BY season
HAVING match_count >= 3250
ORDER BY match_count DESC;
```
평균 홈 득점
```sql
SELECT season, AVG(home_team_goal) AS avg_home_goals
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
ORDER BY avg_home_goals DESC;
```
전체 득점
```sql
SELECT season, SUM(home_team_goal + away_team_goal) AS total_goals
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
ORDER BY total_goals DESC;
```
#### 문제점
각 계산 자체는 할 수 있었지만 문제는 같은 시즌 그룹에서 세 집계값을 동시에 출력하는 것이었다.
`COUNT`, `AVG`, `SUM`을 별도의 쿼리로 나눌 필요가 없다.
---
#### 두 번째 시도
```sql
SELECT season, COUNT(*) AS match_count
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
HAVING match_count >= 3250
ORDER BY match_count DESC;
```
#### 실제 결과


| `season` | `match_count` |
| --- | --- |
| 2015/2016 | 3326 |
| 2014/2015 | 3325 |
| 2012/2013 | 3260 |
| 2010/2011 | 3260 |


평가
`WHERE`, `GROUP BY`, `HAVING`은 정확하게 구성했다.
하지만 여전히 `AVG`와 `SUM`이 빠져 있었다.
---
#### 세 번째 시도
```sql
SELECT season,
       COUNT(*) AS match_count,
       AVG(home_team_goal) AS avg_home_goals,
       SUM(home_team_goal + away_team_goal) AS total_goals
FROM `Match`
WHERE season >= '2010/2011'
GROUP BY season
ORDER BY total_goals DESC;
```
#### 실제 결과


| `season` | `match_count` | `avg_home_goals` | `total_goals` |
| --- | --- | --- | --- |
| 2015/2016 | 3326 | 1.54389657245941 | 9162 |
| 2012/2013 | 3260 | 1.55 | 9039 |
| 2014/2015 | 3325 | 1.5203007518797 | 8897 |
| 2010/2011 | 3260 | 1.54846625766871 | 8749 |
| 2011/2012 | 3220 | 1.57267080745342 | 8747 |
| 2013/2014 | 3032 | 1.57882585751979 | 8389 |


평가
세 개의 집계 함수를 하나의 `SELECT`에서 계산하는 데 성공했다.
하지만:
경기 수가 3,250 이상인 시즌만 출력
이라는 조건이 빠져 있었다.
따라서 2011/2012와 2013/2014도 출력됐다.
---
#### MySQL 8.x 기준 최종 정답
```sql
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
```
#### 실제 결과


| `season` | `match_count` | `avg_home_goals` | `total_goals` |
| --- | --- | --- | --- |
| 2015/2016 | 3326 | 1.54389657245941 | 9162 |
| 2012/2013 | 3260 | 1.55 | 9039 |
| 2014/2015 | 3325 | 1.5203007518797 | 8897 |
| 2010/2011 | 3260 | 1.54846625766871 | 8749 |


---
#### 오늘의 핵심 개념
## 1. `WHERE`와 `HAVING`
오늘 가장 중요한 내용이다.
`WHERE`
원본 데이터의 행을 그룹화 전에 필터링한다.
예:
`WHERE` `season` \>= '2012/2013'
의미:
2012/2013 이후 경기만 먼저 가져온다.
---
`HAVING`
`GROUP BY`와 집계가 이루어진 뒤 그룹의 집계 결과를 필터링한다.
예:
`HAVING` `COUNT`(\*) \>= 3250
의미:
시즌별 경기 수를 계산한 다음 3,250경기 이상인 시즌만 남긴다.
---
## 1. `GROUP BY`에는 그룹 기준을 넣는다
잘못 사용했던 형태:
`GROUP BY` `season` \>= '2012/2013'
이것은 시즌별 그룹화가 아니다.
올바른 구조:
`WHERE` `season` \>= '2012/2013'
`GROUP BY` `season`
즉:
조건 → `WHERE`
그룹 기준 → `GROUP BY`
로 분리한다.
---
## 1. 여러 집계 함수는 동시에 사용할 수 있다
문제 20에서 처음에는:
`COUNT`
`AVG`
`SUM`
을 각각 별도 쿼리로 계산했다.
하지만 같은 `season` 그룹에 대한 지표라면:
```sql
SELECT
season,
COUNT(*) AS match_count,
AVG(home_team_goal) AS avg_home_goals,
SUM(home_team_goal + away_team_goal) AS total_goals
처럼 한 번에 계산할 수 있다.
실제 데이터 분석에서도 하나의 그룹에 대해 여러 KPI를 동시에 계산하는 경우가 많으므로 중요한 패턴이다.
⸻
오늘 사용한 SQL 구조
오늘 문제를 통해 다음 구조를 반복해서 연습했다.
SELECT
grouping_column,
aggregate_function(...)
FROM TABLE
WHERE row_condition
GROUP BY grouping_column
HAVING aggregate_condition
ORDER BY result DESC;
```
논리적으로 생각할 때는:
`FROM`
↓
`WHERE`
↓
`GROUP BY`
↓
`COUNT` / `AVG` / `SUM`
↓
`HAVING`
↓
`ORDER BY`
순서로 생각하면 이해하기 쉽다.
---
#### 오늘의 오류 유형 정리
개념 오류
- `GROUP BY` 없이 시즌별 집계를 시도함
- `GROUP BY` `season` \>= '2012/2013'처럼 조건식을 그룹 기준으로 사용함
- 문제 20에서 여러 집계값을 하나의 쿼리로 합쳐야 한다는 점을 처음에 놓침
문제 조건 해석 오류
- 2010/2011 이후에서 \>와 \>= 혼동
- 평균이 높은 순인데 `ASC`로 정렬
- 경기 수 기준 정렬인데 시즌 기준으로 정렬
- 문제 20에서 `HAVING` `match_count` \>= 3250 조건을 한 번 누락
#### 잘된 부분
- 문제 19는 첫 시도에 정답
- `SUM`(`home_team_goal` + `away_team_goal`) 직접 구성
- 문제 18 이후 `WHERE` → `GROUP BY` → `HAVING` 구조가 개선됨
- 문제 20에서 `COUNT`, `AVG`, `SUM`을 하나의 쿼리로 결합하는 데 성공
- 마지막에는 `WHERE` + `GROUP BY` + `HAVING` + `ORDER BY` 전체 구조를 완성함
---
#### 세션 회고
오늘은 단순한 `GROUP BY` 집계에서 한 단계 올라가 **집계 결과를 다시 필터링하는 ****`HAVING`**을 처음 본격적으로 사용했다.
초반 문제 17에서는 `GROUP BY`를 빼고 `HAVING`부터 사용했고, 문제 18에서는 이전에도 발생했던:
`GROUP BY` `season` \>= '2012/2013'
오류가 다시 나타났다.
따라서 아직 `WHERE`, `GROUP BY`, `HAVING`을 문제 문장에서 즉시 분리하는 과정은 반복 연습이 필요하다.
반면 문제 19에서는 같은 구조를 첫 시도에 정확하게 작성했고, 문제 20에서는 처음에는 집계 지표를 각각 따로 계산했지만 최종적으로:
`WHERE`
- `GROUP BY`
- `COUNT`
- `AVG`
- `SUM`
- `HAVING`
- `ORDER BY`
를 하나의 쿼리에 결합했다.
따라서 현재 단계에서는 새로운 문법을 빠르게 추가하기보다, 오늘 배운 구조를 다른 문제와 데이터에서도 반복해서 사용하면서 문제 문장을 보고 `WHERE` / `GROUP BY` / `HAVING`을 스스로 분리하는 능력을 안정화하는 것이 중요하다.
---
#### 다음 학습 방향
다음 `SQL` 학습에서는 오늘 배운 `HAVING`을 짧게 복습한 뒤 다음 단계로 이동한다.
`WHERE` / `GROUP BY` / `HAVING` 복습
↓
`JOIN` 복습
↓
CASE WHEN
↓
Subquery / CTE
↓
날짜 함수
↓
Window Function
Window Function에서는 최종적으로 다음 범위를 목표로 한다.
`ROW_NUMBER()`
RANK()
`DENSE_RANK()`
`PARTITION BY`
`LAG()`
`LEAD()`
`SUM()` OVER()
`AVG()` OVER()
또한 축구 데이터만 반복해서 패턴을 암기하지 않도록 별도의 비즈니스 데이터셋을 설치하고, 동일한 `SQL` 개념을 다른 도메인의 문제에서도 직접 작성하는 연습을 병행한다.
다음 데이터셋 후보: Olist Brazilian E-Commerce Dataset
목표는 `SQL` 문법 자체를 외우는 것이 아니라, 데이터가 바뀌어도 같은 분석 구조를 스스로 적용할 수 있는지를 확인하는 것이다.
