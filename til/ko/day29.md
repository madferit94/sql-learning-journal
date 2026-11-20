# Day 29 — F1 직전 출전 포인트 비교·팀별 득점률

[English](../en/day29.md) · [목차](../../README.ko.md) · [SQL](../../sql/day29.sql)

MySQL 8.4 / f1_study. 적재된 2026년 본선 20개와 경기 결과 440행을 사용합니다. 그중 미출발은 8행이며 출전 기록 432행을 비교 대상으로 삼습니다. 이 범위에서는 시즌·본선 조건이 이미 데이터에 반영돼 있습니다. 스프린트 등을 나중에 적재한다면 세션을 명시적으로 필터링해야 합니다.

| 테이블 | 한 행의 의미 | 필요한 컬럼 |
| --- | --- | --- |
| sessions | 경기 세션 한 개 | session_key(INT, 고유), year(INT), session_name(VARCHAR(40), 본선은 Race), date_start(VARCHAR(40), UTC 시작 시각) |
| race_results | 경기에서 한 드라이버의 결과 | session_key(INT), driver_number(INT), points(DECIMAL(8,2), 포인트), dns(BOOLEAN, 1은 미출발) |
| drivers | 세션에 등록된 드라이버 한 명 | session_key(INT), driver_number(INT), team_name(VARCHAR(100), 그 경기 소속 팀, NULL은 미기록) |

sessions와 race_results는 session_key로, drivers와 race_results는 session_key와 driver_number를 함께 사용해 연결합니다.

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

```sql
USE f1_study;
```

## 문제 1 — 직전 출전 경기와 포인트 비교

본선 출전마다 현재 포인트와 같은 드라이버의 직전 출전 포인트, 그 차이를 출력합니다. 미출발은 제외하고 0점 출전은 포함합니다. 첫 출전의 두 비교 값은 NULL입니다. 드라이버 번호·시작 시각·세션 ID 오름차순으로 처음 20행을 출력합니다. 가상 예: 10점 → 결장 → 18점이면 차이는 +8점입니다.

### 최종 기록 SQL

```sql
WITH f1_2026 AS (
    SELECT r.driver_number, s.session_key, s.date_start, r.points
    FROM race_results AS r
    JOIN sessions AS s ON s.session_key = r.session_key
    WHERE r.dns = 0
),
previous_point_driver AS (
    SELECT driver_number, session_key, date_start, points,
           LAG(points) OVER (
               PARTITION BY driver_number
               ORDER BY date_start ASC, session_key ASC
           ) AS previous_points
    FROM f1_2026
)
SELECT driver_number, session_key, date_start, points, previous_points,
       points - previous_points AS points_change
FROM previous_point_driver
ORDER BY driver_number ASC, date_start ASC, session_key ASC
LIMIT 20;
```

### 실행 결과

| driver_number | session_key | date_start | points | previous_points | points_change |
| --- | --- | --- | --- | --- | --- |
| 1 | 11234 | 2026-03-08T04:00:00+00:00 | 10.00 | NULL | NULL |
| 1 | 11253 | 2026-03-29T05:00:00+00:00 | 10.00 | 10.00 | 0.00 |
| 1 | 11280 | 2026-05-03T17:00:00+00:00 | 18.00 | 10.00 | 8.00 |
| 1 | 11291 | 2026-05-24T20:00:00+00:00 | 0.00 | 18.00 | -18.00 |
| 1 | 11299 | 2026-06-07T13:00:00+00:00 | 0.00 | 0.00 | 0.00 |
| 1 | 11307 | 2026-06-14T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 1 | 11315 | 2026-06-28T13:00:00+00:00 | 6.00 | 15.00 | -9.00 |
| 1 | 11326 | 2026-07-05T14:00:00+00:00 | 12.00 | 6.00 | 6.00 |
| 1 | 11334 | 2026-07-19T13:00:00+00:00 | 6.00 | 12.00 | -6.00 |
| 1 | 11342 | 2026-07-26T13:00:00+00:00 | 25.00 | 6.00 | 19.00 |
| 1 | 11353 | 2026-08-23T13:00:00+00:00 | 25.00 | 25.00 | 0.00 |
| 1 | 11361 | 2026-09-06T13:00:00+00:00 | 12.00 | 25.00 | -13.00 |
| 1 | 11369 | 2026-09-13T13:00:00+00:00 | 15.00 | 12.00 | 3.00 |
| 1 | 11377 | 2026-09-26T11:00:00+00:00 | 0.00 | 15.00 | -15.00 |
| 1 | 11731 | 2026-10-04T07:00:00+00:00 | 2.00 | 0.00 | 2.00 |
| 1 | 11388 | 2026-10-11T12:00:00+00:00 | 12.00 | 2.00 | 10.00 |
| 1 | 11396 | 2026-10-25T20:00:00+00:00 | 10.00 | 12.00 | -2.00 |
| 1 | 11404 | 2026-11-01T20:00:00+00:00 | 10.00 | 10.00 | 0.00 |
| 1 | 11412 | 2026-11-08T17:00:00+00:00 | 25.00 | 10.00 | 15.00 |
| 3 | 11234 | 2026-03-08T04:00:00+00:00 | 8.00 | NULL | NULL |

직전 경기는 점수순이 아니라 경기 시간순으로 찾습니다. 처음 쿼리의 점수순 LAG는 결과표의 시간순 정렬로 바로잡을 수 없습니다. 최종 계산은 이번 포인트 − 이미 구한 직전 포인트입니다. 실제로 1번 드라이버는 미출발인 11245를 건너뛰어 11253을 11234와 비교합니다.

## 문제 2 — 직전 출전보다 포인트가 오른 경기

직전 출전보다 포인트가 오른 경기만 드라이버·경기당 한 행으로 조회합니다. 첫 출전, 동률과 하락은 제외합니다. 전체 출전에서 계산하고 증가량 내림차순·드라이버 번호·시작 시각·세션 ID 오름차순으로 처음 20행을 출력합니다. 가상 예: 0 → 8은 포함하고 8 → 8은 제외합니다.

### 최종 기록 SQL

```sql
WITH f1_2026 AS (
    SELECT r.driver_number, s.session_key, s.date_start, r.points
    FROM race_results AS r
    JOIN sessions AS s ON s.session_key = r.session_key
    WHERE r.dns = 0
),
previous_point_driver AS (
    SELECT driver_number, session_key, date_start, points,
           LAG(points) OVER (
               PARTITION BY driver_number
               ORDER BY date_start ASC, session_key ASC
           ) AS previous_points
    FROM f1_2026
)
SELECT driver_number, session_key, date_start, points, previous_points,
       points - previous_points AS points_change
FROM previous_point_driver
WHERE points > previous_points
ORDER BY points_change DESC, driver_number ASC, date_start ASC, session_key ASC
LIMIT 20;
```

### 실행 결과

| driver_number | session_key | date_start | points | previous_points | points_change |
| --- | --- | --- | --- | --- | --- |
| 12 | 11334 | 2026-07-19T13:00:00+00:00 | 25.00 | 0.00 | 25.00 |
| 16 | 11326 | 2026-07-05T14:00:00+00:00 | 25.00 | 4.00 | 21.00 |
| 1 | 11342 | 2026-07-26T13:00:00+00:00 | 25.00 | 6.00 | 19.00 |
| 63 | 11307 | 2026-06-14T13:00:00+00:00 | 18.00 | 0.00 | 18.00 |
| 1 | 11307 | 2026-06-14T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 1 | 11412 | 2026-11-08T17:00:00+00:00 | 25.00 | 10.00 | 15.00 |
| 3 | 11334 | 2026-07-19T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 3 | 11361 | 2026-09-06T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 12 | 11315 | 2026-06-28T13:00:00+00:00 | 15.00 | 0.00 | 15.00 |
| 63 | 11377 | 2026-09-26T11:00:00+00:00 | 25.00 | 10.00 | 15.00 |
| 6 | 11412 | 2026-11-08T17:00:00+00:00 | 15.00 | 2.00 | 13.00 |
| 3 | 11307 | 2026-06-14T13:00:00+00:00 | 12.00 | 0.00 | 12.00 |
| 16 | 11369 | 2026-09-13T13:00:00+00:00 | 12.00 | 0.00 | 12.00 |
| 81 | 11299 | 2026-06-07T13:00:00+00:00 | 12.00 | 0.00 | 12.00 |
| 1 | 11388 | 2026-10-11T12:00:00+00:00 | 12.00 | 2.00 | 10.00 |
| 3 | 11404 | 2026-11-01T20:00:00+00:00 | 25.00 | 15.00 | 10.00 |
| 6 | 11291 | 2026-05-24T20:00:00+00:00 | 10.00 | 0.00 | 10.00 |
| 12 | 11396 | 2026-10-25T20:00:00+00:00 | 25.00 | 15.00 | 10.00 |
| 44 | 11291 | 2026-05-24T20:00:00+00:00 | 18.00 | 8.00 | 10.00 |
| 81 | 11334 | 2026-07-19T13:00:00+00:00 | 10.00 | 0.00 | 10.00 |

수정 전에도 20번째 증가량이 +10점이라 상위 20행이 같았습니다. 하지만 정렬만 하면 증가가 아닌 행도 남을 수 있으므로, 직전 값을 구한 뒤 이번 점수가 더 큰 행을 명시적으로 필터링합니다.

## 문제 3 — 직전 출전보다 포인트가 오른 경기 수

전체 본선 출전을 대상으로 직전 출전보다 득점이 늘어난 경기 수를 드라이버당 한 행으로 표시합니다. 증가가 한 번도 없는 드라이버는 제외합니다. 증가 횟수 내림차순·드라이버 번호 오름차순으로 처음 20행을 출력합니다. 가상 예: 0 → 8 → 8 → 10은 두 번 증가했습니다.

### 최종 기록 SQL

```sql
WITH f1_2026 AS (
    SELECT r.driver_number, s.session_key, s.date_start, r.points
    FROM race_results AS r
    JOIN sessions AS s ON s.session_key = r.session_key
    WHERE r.dns = 0
),
previous_point_driver AS (
    SELECT driver_number, session_key, date_start, points,
           LAG(points) OVER (
               PARTITION BY driver_number
               ORDER BY date_start ASC, session_key ASC
           ) AS previous_points
    FROM f1_2026
)
SELECT driver_number,
       COUNT(CASE WHEN points - previous_points > 0 THEN 1 END) AS points_increase_count
FROM previous_point_driver
GROUP BY driver_number
HAVING points_increase_count >= 1
ORDER BY points_increase_count DESC, driver_number ASC
LIMIT 20;
```

### 실행 결과

| driver_number | points_increase_count |
| --- | --- |
| 3 | 11 |
| 63 | 10 |
| 30 | 9 |
| 44 | 9 |
| 1 | 8 |
| 81 | 8 |
| 6 | 7 |
| 10 | 7 |
| 12 | 7 |
| 43 | 7 |
| 16 | 6 |
| 27 | 5 |
| 41 | 4 |
| 14 | 3 |
| 31 | 3 |
| 55 | 3 |
| 87 | 3 |
| 5 | 2 |
| 23 | 2 |
| 22 | 1 |

출전 행에서 직전 포인트를 계산한 뒤에만 드라이버별로 묶습니다. 조건부 COUNT에는 첫 출전의 NULL이나 동률이 포함되지 않습니다. HAVING은 다 센 뒤 증가 횟수가 0인 드라이버를 제거합니다.

## 문제 4 — 팀별 득점률 상위 드라이버 2명

팀 이름이 없는 행과 미출발을 뺀 뒤, 해당 팀 소속으로 5경기 이상 출전한 드라이버 중 최대 2명을 뽑습니다. 한 선수가 팀을 옮기면 팀마다 따로 집계합니다. 득점률은 포인트가 0보다 큰 출전 수를 전체 출전 수로 나눈 값입니다. 순서는 반올림 전 득점률 내림차순, 총 포인트 내림차순, 드라이버 번호 오름차순입니다. 출력 시에만 비율을 소수 둘째 자리로 반올림하고 팀·선택 번호 오름차순으로 표시합니다. 가상 예: 10회 중 8회와 5회 중 5회라면 100%인 후자가 먼저입니다.

### 최종 기록 SQL

```sql
WITH team_driver_stats AS (
    SELECT d.team_name, d.driver_number,
           COUNT(*) AS race_count,
           COUNT(CASE WHEN r.points > 0 THEN 1 END) AS scoring_race_count,
           SUM(r.points) AS total_points
    FROM drivers AS d
    JOIN race_results AS r
      ON r.session_key = d.session_key
     AND r.driver_number = d.driver_number
    WHERE r.dns = 0
      AND d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number
    HAVING COUNT(*) >= 5
),
team_ranked AS (
    SELECT team_name, driver_number, race_count, scoring_race_count, total_points,
           ROW_NUMBER() OVER (
               PARTITION BY team_name
               ORDER BY scoring_race_count / race_count DESC,
                        total_points DESC,
                        driver_number ASC
           ) AS selection_no
    FROM team_driver_stats
)
SELECT team_name, selection_no, driver_number, race_count, scoring_race_count,
       ROUND(scoring_race_count / race_count * 100, 2) AS scoring_rate,
       total_points
FROM team_ranked
WHERE selection_no <= 2
ORDER BY team_name ASC, selection_no ASC;
```

### 실행 결과

| team_name | selection_no | driver_number | race_count | scoring_race_count | scoring_rate | total_points |
| --- | --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | 20 | 10 | 50.00 | 40.00 |
| Alpine | 2 | 43 | 20 | 8 | 40.00 | 27.00 |
| Aston Martin | 1 | 14 | 20 | 3 | 15.00 | 7.00 |
| Aston Martin | 2 | 18 | 20 | 0 | 0.00 | 0.00 |
| Audi | 1 | 27 | 19 | 5 | 26.32 | 12.00 |
| Audi | 2 | 5 | 19 | 4 | 21.05 | 14.00 |
| Cadillac | 1 | 11 | 20 | 0 | 0.00 | 0.00 |
| Cadillac | 2 | 77 | 19 | 0 | 0.00 | 0.00 |
| Ferrari | 1 | 44 | 20 | 19 | 95.00 | 234.00 |
| Ferrari | 2 | 16 | 20 | 17 | 85.00 | 215.00 |
| Haas F1 Team | 1 | 87 | 20 | 4 | 20.00 | 19.00 |
| Haas F1 Team | 2 | 31 | 18 | 3 | 16.67 | 7.00 |
| McLaren | 1 | 1 | 19 | 16 | 84.21 | 213.00 |
| McLaren | 2 | 81 | 18 | 13 | 72.22 | 131.00 |
| Mercedes | 1 | 12 | 20 | 18 | 90.00 | 359.00 |
| Mercedes | 2 | 63 | 20 | 16 | 80.00 | 228.00 |
| Racing Bulls | 1 | 30 | 17 | 13 | 76.47 | 68.00 |
| Racing Bulls | 2 | 41 | 19 | 11 | 57.89 | 37.00 |
| Red Bull Racing | 1 | 6 | 17 | 14 | 82.35 | 122.00 |
| Red Bull Racing | 2 | 3 | 20 | 16 | 80.00 | 259.00 |
| Williams | 1 | 55 | 20 | 4 | 20.00 | 7.00 |
| Williams | 2 | 23 | 19 | 2 | 10.53 | 5.00 |

**왜 5경기 이상인가?** 1경기에서 1회 득점하면 100%이지만 한 경기만으로 비교하면 적은 출전 기록의 비율이 앞설 수 있습니다. 5경기는 이번 문제에서 정한 최소 비교 기준이며 F1 공식 규정이나 통계적 보장 기준은 아닙니다. 팀·드라이버별 집계 후 HAVING COUNT(*) >= 5를 적용합니다. 정확히 5경기는 포함하며 다른 팀 출전은 더하지 않습니다. 0점으로 출전한 경기는 분모에 남습니다.

## 문제 5 — 팀별 상위 드라이버의 합산 득점률

4번과 같은 기준으로 팀별 최대 2명을 선정합니다. 그들의 득점 출전 수 합계를 출전 수 합계로 나눠 팀당 한 행으로 표시합니다. 같은 경기라도 두 드라이버가 출전했다면 각각 한 건입니다. 한 명만 선정된 팀도 포함합니다. 비율은 소수 둘째 자리까지 표시하고 팀 이름 오름차순으로 정렬합니다. 가상 예: 8/10과 3/5를 합치면 11/15 = 73.33%입니다. 개인 비율의 단순 평균인 70%와 다릅니다.

### 최종 기록 SQL

```sql
WITH team_driver_stats AS (
    SELECT d.team_name, d.driver_number,
           COUNT(*) AS race_count,
           COUNT(CASE WHEN r.points > 0 THEN 1 END) AS scoring_race_count,
           SUM(r.points) AS total_points
    FROM drivers AS d
    JOIN race_results AS r
      ON r.session_key = d.session_key
     AND r.driver_number = d.driver_number
    WHERE r.dns = 0
      AND d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number
    HAVING COUNT(*) >= 5
),
team_ranked AS (
    SELECT team_name, driver_number, race_count, scoring_race_count, total_points,
           ROW_NUMBER() OVER (
               PARTITION BY team_name
               ORDER BY scoring_race_count / race_count DESC,
                        total_points DESC,
                        driver_number ASC
           ) AS selection_no
    FROM team_driver_stats
)
SELECT team_name,
       COUNT(*) AS selected_driver_count,
       SUM(race_count) AS total_race_count,
       SUM(scoring_race_count) AS total_scoring_race_count,
       ROUND(SUM(scoring_race_count) / SUM(race_count) * 100, 2) AS combined_scoring_rate
FROM team_ranked
WHERE selection_no <= 2
GROUP BY team_name
ORDER BY team_name ASC;
```

### 실행 결과

| team_name | selected_driver_count | total_race_count | total_scoring_race_count | combined_scoring_rate |
| --- | --- | --- | --- | --- |
| Alpine | 2 | 40 | 18 | 45.00 |
| Aston Martin | 2 | 40 | 3 | 7.50 |
| Audi | 2 | 38 | 9 | 23.68 |
| Cadillac | 2 | 39 | 0 | 0.00 |
| Ferrari | 2 | 40 | 36 | 90.00 |
| Haas F1 Team | 2 | 38 | 7 | 18.42 |
| McLaren | 2 | 37 | 29 | 78.38 |
| Mercedes | 2 | 40 | 34 | 85.00 |
| Racing Bulls | 2 | 36 | 24 | 66.67 |
| Red Bull Racing | 2 | 37 | 30 | 81.08 |
| Williams | 2 | 39 | 6 | 15.38 |

**4번과 달라지는 부분:** 첫 두 CTE와 상위 2명 필터는 그대로입니다. 4번의 마지막 SELECT는 드라이버별 상세값을 출력했습니다. 5번은 선택 행을 GROUP BY team_name으로 묶고, COUNT(*)로 드라이버 수를, SUM(race_count)로 출전 수를, SUM(scoring_race_count)로 득점 출전 수를 구합니다. 마지막 정렬은 팀 이름만 사용합니다. Red Bull Racing의 실제 결과는 37회 중 30회 득점, 81.08%입니다.
