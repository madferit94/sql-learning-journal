# Day 24 — F1 집계·CTE·순위·소속 팀 보완

[English](../en/day24.md) · [목차](../../README.ko.md)

<details>
<summary>🏎️ Day24 — F1 집계 복습·CTE·순위·소속 팀 결측값 처리</summary>

# SQL 학습 기록 — Day 24

## 학습 개요

- 환경: MySQL / f1_study
- 대상: 브라질까지 적재된 2026년 본선 20경기
- 범위: JOIN·조건부 집계·CTE·전체 순위·팀 내 순위·CASE를 이용한 소속 팀 보완
- 검증 근거: 최종 제출 SQL과 공유한 MySQL 실행 결과
- 1\~2번은 브라질 세션 11412만, 3\~5-2번은 적재된 전체 20경기를 사용합니다.
- 스프린트·예선·연습은 제외합니다. 본선 포인트 합계와 RANK는 공식 챔피언십 점수·동점 처리 규칙과 구분합니다.
- 이번에는 랩타임 비교가 아니므로 40랩 조건을 적용하지 않습니다.
- 원본 team_name NULL은 보존하고 5-2에서만 근거가 확인된 기록을 조회 단계에서 보완합니다.

## 접속

일반 터미널:

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

mysql> 화면:

```sql
USE f1_study;
```

<details>
<summary>📚 문제 1 — 브라질 GP 팀별 결과 집계</summary>

### 테이블과 한 행의 의미

drivers의 한 행은 특정 경기의 드라이버 한 명이며, race_results의 한 행은 그 경기의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 경기 당시 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 본선 획득 포인트 |
| race_results | status | VARCHAR(20) | FINISHED·DNF·DNS 등의 상태 |

각 테이블의 식별 키는 session_key + driver_number입니다. 두 테이블을 연결할 때 두 키를 함께 사용합니다. 현재 적재된 결과의 points·completed_laps에는 NULL이 없습니다. team_name에는 소속 미확인 NULL이 있으며, 0점은 결측값이 아닙니다.

### 문제와 조건

브라질 본선 결과를 팀별로 집계해 등록 드라이버 수·완료 랩 합계·포인트 합계를 조회합니다.

- 두 테이블을 연결하고 세션 11412만 사용합니다.
- 0점·DNF·DNS도 포함하며, 실제 출발 여부와 관계없이 결과표 등록 인원을 셉니다.
- 포인트 합계 내림차순, 동점이면 팀 이름 오름차순입니다.
- 팀 제외 조건은 없습니다. 결과 한 행은 브라질 GP의 팀 하나입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 팀 이름 |
| driver_count | 결과표 등록 인원 |
| total_laps | 완료 랩 합계 |
| total_points | 포인트 합계 |

### 가상 예시

가상 Team A 두 드라이버가 각각 71랩·30랩, 10점·0점이라면 등록 인원 2명·완료 101랩·합계 10점입니다. 실제 결과가 아닙니다.

### 최종 SQL

```sql
SELECT d.team_name, COUNT(d.driver_number) AS driver_count,
       SUM(completed_laps) AS total_laps, SUM(points) AS total_points
FROM drivers d
JOIN race_results r
    ON r.driver_number = d.driver_number
   AND r.session_key = d.session_key
WHERE r.session_key = 11412
GROUP BY d.team_name
ORDER BY total_points DESC, d.team_name ASC;
```

### 실제 실행 결과 — 전체 출력

| team_name | driver_count | total_laps | total_points |
| --- | --- | --- | --- |
| McLaren | 2 | 142 | 33.00 |
| Red Bull Racing | 2 | 142 | 33.00 |
| Mercedes | 2 | 142 | 22.00 |
| Ferrari | 2 | 141 | 6.00 |
| Racing Bulls | 2 | 141 | 6.00 |
| Audi | 2 | 140 | 1.00 |
| Alpine | 2 | 140 | 0.00 |
| Aston Martin | 2 | 100 | 0.00 |
| Cadillac | 2 | 69 | 0.00 |
| Haas F1 Team | 2 | 139 | 0.00 |
| Williams | 2 | 139 | 0.00 |

11 rows in set (0.01 sec)

최종 정답. 실행 시간·결과표는 공유한 사용자 터미널 기록이며 업로드를 위해 새로 실행하지 않았습니다.

### 이해할 부분과 결과 해석

두 키 JOIN 이후 한 행은 한 경기의 드라이버 한 명입니다. driver_number는 NULL 불가이므로 COUNT(driver_number)는 COUNT(\*)와 같습니다. Cadillac은 완료 랩 합계 69여도 DNS 포함 등록 인원은 2명입니다. McLaren·Red Bull Racing은 33점으로 같아 팀 이름으로 정렬됩니다.
</details>

<details>
<summary>📚 문제 2 — 브라질 GP 득점 드라이버 비율</summary>

### 테이블과 한 행의 의미

race_results의 한 행은 특정 경기의 드라이버 한 명에 대한 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 설명 |
| --- | --- | --- | --- |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 본선 획득 포인트 |
| race_results | status | VARCHAR(20) | FINISHED·DNF·DNS 등의 상태 |

각 테이블의 식별 키는 session_key + driver_number입니다. 현재 적재된 결과의 points·completed_laps에는 NULL이 없습니다. team_name에는 소속 미확인 NULL이 있으며, 0점은 결측값이 아닙니다.

### 문제와 조건

브라질 전체 등록 드라이버 중 득점한 인원과 비율을 조회합니다.

- race_results만 사용하고 세션 11412만 대상으로 합니다.
- points > 0이면 득점 드라이버입니다.
- 분모에는 0점·DNF·DNS도 포함합니다.
- 득점 인원 ÷ 전체 등록 인원 × 100을 마지막에 소수 둘째 자리까지 반올림합니다.
- 인원수는 데이터에서 계산합니다. 최종 한 행이며 정렬은 필요하지 않습니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| total_driver_count | 전체 등록 인원 |
| scoring_driver_count | 0점 초과 인원 |
| scoring_rate | 득점 비율(%) |

### 가상 예시

가상 전체 20명 중 8명이 득점했다면 8 ÷ 20 × 100 = 40.00%입니다. 실제 결과가 아닙니다.

### 최종 SQL

```sql
SELECT COUNT(driver_number) AS total_driver_count,
       COUNT(CASE WHEN points > 0 THEN 1 END) AS scoring_driver_count,
       ROUND(COUNT(CASE WHEN points > 0 THEN 1 END)
             / COUNT(driver_number) * 100, 2) AS scoring_rate
FROM race_results
WHERE session_key = 11412;
```

### 실제 실행 결과 — 전체 출력

| total_driver_count | scoring_driver_count | scoring_rate |
| --- | --- | --- |
| 22 | 10 | 45.45 |

1 rows in set (0.00 sec)

최종 정답. 실행 시간·결과표는 공유한 사용자 터미널 기록이며 업로드를 위해 새로 실행하지 않았습니다.

### 이해할 부분과 결과 해석

WHERE는 브라질만 선택해 전체 22명을 유지합니다. 조건부 COUNT가 득점한 10명만 세어 10 ÷ 22 × 100 = 45.45%입니다. WHERE points > 0으로 먼저 제외하면 전체 등록 인원을 분모로 사용할 수 없습니다.
</details>

<details>
<summary>🧩 문제 3 — CTE로 누적 100점 이상 드라이버 조회</summary>

### 테이블과 한 행의 의미

drivers의 한 행은 특정 경기의 드라이버 한 명이며, race_results의 한 행은 그 경기의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 경기 당시 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 본선 획득 포인트 |
| race_results | status | VARCHAR(20) | FINISHED·DNF·DNS 등의 상태 |

각 테이블의 식별 키는 session_key + driver_number입니다. 두 테이블을 연결할 때 두 키를 함께 사용합니다. 현재 적재된 결과의 points·completed_laps에는 NULL이 없습니다. team_name에는 소속 미확인 NULL이 있으며, 0점은 결측값이 아닙니다.

### 문제와 조건

전체 20개 본선에서 드라이버별 등록 경기 수와 누적 포인트를 계산하고 100점 이상인 드라이버를 조회합니다.

- CTE와 두 테이블을 사용합니다.
- 드라이버 번호·이름을 기준으로 집계합니다. 이적해도 같은 드라이버의 점수는 합산합니다.
- DNS·DNF·0점도 경기 수에 포함합니다. 실제 출발 횟수와 구분합니다.
- 누적 100점 이상을 포함합니다.
- 누적 포인트 내림차순, 동점이면 드라이버 번호 오름차순입니다.
- 결과 한 행은 드라이버 한 명입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| race_count | 결과표 등록 경기 수 |
| total_points | 본선 누적 포인트 |

### 가상 예시

가상 누적 100점 드라이버는 포함하고 99점 드라이버는 제외합니다. 실제 결과가 아닙니다.

### 최종 SQL

```sql
WITH 2026_f1 AS (
    SELECT d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    GROUP BY driver_number, full_name
)
SELECT driver_number, full_name, race_count, total_points
FROM 2026_f1
WHERE total_points >= 100
ORDER BY total_points DESC, driver_number ASC;
```

### 실제 실행 결과 — 전체 출력

| driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- |
| 12 | Kimi ANTONELLI | 20 | 359.00 |
| 3 | Max VERSTAPPEN | 20 | 259.00 |
| 44 | Lewis HAMILTON | 20 | 234.00 |
| 63 | George RUSSELL | 20 | 228.00 |
| 16 | Charles LECLERC | 20 | 215.00 |
| 1 | Lando NORRIS | 20 | 213.00 |
| 81 | Oscar PIASTRI | 20 | 131.00 |
| 6 | Isack HADJAR | 17 | 122.00 |

8 rows in set (0.13 sec)

최종 정답. 실행 시간·결과표는 공유한 사용자 터미널 기록이며 업로드를 위해 새로 실행하지 않았습니다.

### 이해할 부분과 결과 해석

여러 번 수정하며 오류를 직접 찾아 최종 SQL을 완성했습니다. 중간 SQL·오류 메시지는 공유되지 않아 추정해 기록하지 않습니다. CTE 안쪽에서 드라이버별 한 행을 만들고 바깥에서는 이미 계산된 total_points를 필터링합니다. 같은 기준으로 다시 GROUP BY할 필요가 없습니다. 바깥 집계 여부는 그 단계에서 원하는 한 행의 의미로 판단합니다.
</details>

<details>
<summary>🏁 문제 4 — 전체 드라이버 누적 포인트 순위</summary>

### 테이블과 한 행의 의미

drivers의 한 행은 특정 경기의 드라이버 한 명이며, race_results의 한 행은 그 경기의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 경기 당시 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 본선 획득 포인트 |
| race_results | status | VARCHAR(20) | FINISHED·DNF·DNS 등의 상태 |

각 테이블의 식별 키는 session_key + driver_number입니다. 두 테이블을 연결할 때 두 키를 함께 사용합니다. 현재 적재된 결과의 points·completed_laps에는 NULL이 없습니다. team_name에는 소속 미확인 NULL이 있으며, 0점은 결측값이 아닙니다.

### 문제와 조건

전체 20개 본선에서 드라이버별 등록 경기 수·누적 포인트와 전체 순위를 조회합니다.

- CTE와 RANK를 사용하고 두 테이블을 연결합니다.
- 드라이버 번호·이름으로 집계하며 이적해도 합산합니다.
- 100점 필터 없이 0점·DNS·DNF 기록도 포함합니다.
- 같은 포인트는 공동 순위이고 다음 순위는 건너뜁니다.
- 최종 순위 오름차순, 동점이면 드라이버 번호 오름차순입니다.
- 결과 한 행은 드라이버 한 명입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| points_rank | 누적 포인트 전체 순위 |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| race_count | 결과표 등록 경기 수 |
| total_points | 본선 누적 포인트 |

### 가상 예시

가상 포인트가 180·150·150·100이면 순위는 1·2·2·4입니다. 실제 결과가 아닙니다.

### 최종 SQL

```sql
WITH 2026_f1 AS (
    SELECT d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    GROUP BY d.driver_number, d.full_name
)
SELECT RANK() OVER (ORDER BY total_points DESC) AS points_rank,
       driver_number, full_name, race_count, total_points
FROM 2026_f1
ORDER BY points_rank ASC, driver_number ASC;
```

### 실제 실행 결과 — 전체 출력

| points_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- |
| 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| 2 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| 3 | 44 | Lewis HAMILTON | 20 | 234.00 |
| 4 | 63 | George RUSSELL | 20 | 228.00 |
| 5 | 16 | Charles LECLERC | 20 | 215.00 |
| 6 | 1 | Lando NORRIS | 20 | 213.00 |
| 7 | 81 | Oscar PIASTRI | 20 | 131.00 |
| 8 | 6 | Isack HADJAR | 17 | 122.00 |
| 9 | 30 | Liam LAWSON | 20 | 82.00 |
| 10 | 10 | Pierre GASLY | 20 | 40.00 |
| 11 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| 12 | 43 | Franco COLAPINTO | 20 | 27.00 |
| 13 | 87 | Oliver BEARMAN | 20 | 19.00 |
| 14 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| 15 | 27 | Nico HULKENBERG | 20 | 12.00 |
| 16 | 14 | Fernando ALONSO | 20 | 7.00 |
| 16 | 31 | Esteban OCON | 18 | 7.00 |
| 16 | 55 | Carlos SAINZ | 20 | 7.00 |
| 19 | 23 | Alexander ALBON | 20 | 5.00 |
| 20 | 22 | Yuki TSUNODA | 3 | 1.00 |
| 20 | 50 | Ryo HIRAKAWA | 1 | 1.00 |
| 22 | 11 | Sergio PEREZ | 20 | 0.00 |
| 22 | 18 | Lance STROLL | 20 | 0.00 |
| 22 | 51 | Rafael CAMARA | 1 | 0.00 |
| 22 | 77 | Valtteri BOTTAS | 20 | 0.00 |

25 rows in set (0.17 sec)

최종 정답. 실행 시간·결과표는 공유한 사용자 터미널 기록이며 업로드를 위해 새로 실행하지 않았습니다.

### 이해할 부분과 결과 해석

7점인 Alonso·Ocon·Sainz는 공동 16위이고 다음 Albon은 19위입니다. OVER 안 ORDER BY는 순위 계산, 마지막 ORDER BY는 화면 표시 순서입니다. 포인트만으로 공동 순위를 계산하고 번호는 출력 동점 순서에만 사용했습니다.
</details>

<details>
<summary>🏁 문제 5-1 — 원본 소속 팀 기준 팀별 순위</summary>

### 테이블과 한 행의 의미

drivers의 한 행은 특정 경기의 드라이버 한 명이며, race_results의 한 행은 그 경기의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 경기 당시 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 본선 획득 포인트 |
| race_results | status | VARCHAR(20) | FINISHED·DNF·DNS 등의 상태 |

각 테이블의 식별 키는 session_key + driver_number입니다. 두 테이블을 연결할 때 두 키를 함께 사용합니다. 현재 적재된 결과의 points·completed_laps에는 NULL이 없습니다. team_name에는 소속 미확인 NULL이 있으며, 0점은 결측값이 아닙니다.

### 문제와 조건

각 드라이버가 각 팀 소속으로 기록한 경기 수·포인트 합계와 팀 내 순위를 조회합니다.

- CTE와 윈도우 함수를 사용하고 전체 20개 본선을 두 테이블로 집계합니다.
- 팀 이름·드라이버 번호·이름으로 묶습니다. 이적한 드라이버는 팀별로 나눕니다.
- 0점·DNS·DNF도 포함합니다.
- 팀 안에서 같은 점수는 공동 순위, 다음 순위는 건너뜁니다.
- 팀 이름 → 팀 내 순위 → 드라이버 번호 순으로 모두 오름차순입니다.
- 원본 소속 팀 NULL을 제외하거나 바꾸지 않습니다.
- 결과 한 행은 팀 하나와 드라이버 한 명의 조합입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 경기 당시 팀 |
| team_rank | 팀 내 포인트 순위 |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| race_count | 그 팀 소속 등록 경기 수 |
| total_points | 그 팀에서 획득한 포인트 |

### 가상 예시

가상 Driver A가 Team A에서 90점·Team B에서 30점을 얻었다면 두 행으로 나누고 각 팀 안에서 순위를 계산합니다. 실제 결과가 아닙니다.

### 최종 SQL

```sql
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    GROUP BY d.team_name, d.driver_number, d.full_name
)
SELECT team_name,
       RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
       driver_number, full_name, race_count, total_points
FROM 2026_f1
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### 실제 실행 결과 — 전체 출력

| team_name | team_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| NULL | 1 | 50 | Ryo HIRAKAWA | 1 | 1.00 |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| Haas F1 Team | 3 | 51 | Rafael CAMARA | 1 | 0.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Racing Bulls | 3 | 22 | Yuki TSUNODA | 3 | 1.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Red Bull Racing | 3 | 30 | Liam LAWSON | 3 | 14.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

26 rows in set (0.11 sec)

최종 정답. 실행 시간·결과표는 공유한 사용자 터미널 기록이며 업로드를 위해 새로 실행하지 않았습니다.

### 이해할 부분과 결과 해석

료의 팀 NULL을 보고 실제 소속이 하스인지 확인했습니다. 저장된 멕시코 공식 결과 원문에서 세션 11404·드라이버 50은 Haas F1 Team·10위·1점으로 확인됐습니다. [F1 멕시코 공식 결과](https://www.formula1.com/en/results/2026/races/1298/mexico/race-result). 쿼리는 원본대로 올바르게 집계했지만 누락된 팀은 별도 그룹이 됐습니다. NULL 그룹의 1위는 실제 팀 내 1위가 아닙니다. Lawson은 Racing Bulls 68점·Red Bull Racing 14점으로 분리됐고 Cadillac 0점 두 명은 공동 1위입니다.
</details>

<details>
<summary>🧩 문제 5-2 — 소속 팀 보완 후 팀별 순위</summary>

### 테이블과 한 행의 의미

drivers의 한 행은 특정 경기의 드라이버 한 명이며, race_results의 한 행은 그 경기의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 경기 당시 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 본선 획득 포인트 |
| race_results | status | VARCHAR(20) | FINISHED·DNF·DNS 등의 상태 |

각 테이블의 식별 키는 session_key + driver_number입니다. 두 테이블을 연결할 때 두 키를 함께 사용합니다. 현재 적재된 결과의 points·completed_laps에는 NULL이 없습니다. team_name에는 소속 미확인 NULL이 있으며, 0점은 결측값이 아닙니다.

### 문제와 조건

확인된 료의 멕시코 기록만 조회 단계에서 하스로 보완한 뒤, 5-1과 같은 팀별 집계·순위를 다시 계산합니다.

- 세션 11404·드라이버 50·team_name IS NULL인 기록만 Haas F1 Team으로 보완합니다.
- 다른 NULL을 일괄 하스로 바꾸지 않습니다.
- 전체 20개 본선, 동률·최종 정렬·등록 경기 수 기준은 5-1과 같습니다.
- 원본 DB를 UPDATE하지 않습니다.
- 집계와 순위 전에 보완한 팀 이름을 적용합니다.
- 결과 한 행은 팀 하나와 드라이버 한 명의 조합입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 근거에 따라 보완한 팀 |
| team_rank | 팀 내 포인트 순위 |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| race_count | 그 팀 소속 등록 경기 수 |
| total_points | 그 팀에서 획득한 포인트 |

### 가상 예시

가상 특정 드라이버의 누락된 소속이 Team A로 확인되면 집계 전에 보완합니다. NULL을 가진 다른 드라이버까지 Team A로 바꾸지 않습니다. 실제 결과가 아닙니다.

### 실행 SQL

```sql
WITH corrected_results AS (
    SELECT
        CASE
            WHEN d.session_key = 11404
                 AND d.driver_number = 50
                 AND d.team_name IS NULL
            THEN 'Haas F1 Team'
            ELSE d.team_name
        END AS team_name,
        d.driver_number,
        d.full_name,
        r.points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
),
team_driver_totals AS (
    SELECT team_name, driver_number, full_name,
           COUNT(*) AS race_count, SUM(points) AS total_points
    FROM corrected_results
    GROUP BY team_name, driver_number, full_name
)
SELECT team_name,
       RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
       driver_number, full_name, race_count, total_points
FROM team_driver_totals
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### 실제 실행 결과 — 전체 출력

| team_name | team_rank | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| Haas F1 Team | 3 | 50 | Ryo HIRAKAWA | 1 | 1.00 |
| Haas F1 Team | 4 | 51 | Rafael CAMARA | 1 | 0.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Racing Bulls | 3 | 22 | Yuki TSUNODA | 3 | 1.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Red Bull Racing | 3 | 30 | Liam LAWSON | 3 | 14.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

26 rows in set (0.10 sec)

보완 결과 확인. 실행 시간·결과표는 공유한 사용자 터미널 기록이며 업로드를 위해 새로 실행하지 않았습니다.

### 이해할 부분과 결과 해석

제공된 예시 쿼리를 실행해 변화를 확인한 번외 실습입니다. 소속 보완 → 팀·드라이버별 집계 → 팀 내 순위 순으로 처리했습니다. 료가 하스 3위·1점으로 들어가고 카마라는 4위·0점이 됩니다. 료의 행이 하스로 이동했으므로 전체 26행은 유지됩니다. 조회 중 CASE 처리이며 DB 원본은 변경하지 않았습니다.
</details>

<details>
<summary>🔎 이해 정리 — NULL 처리·집계 단계·순위</summary>

## IFNULL·COALESCE·CASE

```sql
IFNULL(d.team_name, '소속 미확인')
COALESCE(d.team_name, '소속 미확인')
```

IFNULL은 첫 값이 NULL일 때 대체값을 반환하고, COALESCE는 앞에서부터 처음 NULL이 아닌 값을 선택합니다. Oracle의 NVL과 유사한 두 인자 NULL 대체는 MySQL에서 IFNULL로 표현할 수 있습니다.

IFNULL(team_name, 'Haas F1 Team')은 모든 소속 누락을 하스로 바꾸므로 이번 보완에는 적절하지 않습니다. 실제 소속의 근거는 NULL 자체가 아니라 해당 경기의 공식 결과입니다. CASE로 확인된 세션·드라이버·NULL 조건만 좁혀 처리했습니다.

## 안쪽·바깥쪽 GROUP BY

- 현재 드라이버별 한 행을 그대로 조회·필터링하면 바깥 그룹화는 불필요합니다.
- 조건 통과 드라이버 전체 인원만 요약하면 바깥 COUNT(\*)를 쓰며 GROUP BY는 필요하지 않습니다.
- 팀·드라이버별 중간 결과를 다시 팀별 합계로 묶으면 바깥 GROUP BY team_name이 필요합니다.

## COUNT와 전체 분모

COUNT(\*)는 행 수, COUNT(컬럼)는 해당 값이 NULL이 아닌 행 수입니다. 0도 셉니다. 조건부 COUNT에서는 조건 불충족 시 NULL이 되도록 합니다. 전체 대비 비율에서는 분모에 포함할 행을 먼저 제거하지 않습니다.

## 순위와 보완 시점

PARTITION BY는 비교 집단을 나눕니다. OVER 안 ORDER BY와 최종 ORDER BY는 역할이 다릅니다. 최종 출력에서 팀 이름만 바꾸면 이미 계산한 집계·순위가 합쳐지지 않으므로 보완은 집계 전에 적용합니다.
</details>

<details>
<summary>🧠 결과 요약·복습 체크</summary>

| 문제 | 결과 |
| --- | --- |
| 1 — 브라질 GP 팀별 결과 집계 | 11행 / 0.01초 |
| 2 — 브라질 GP 득점 드라이버 비율 | 1행 / 0.00초 |
| 3 — CTE로 누적 100점 이상 드라이버 조회 | 8행 / 0.13초 |
| 4 — 전체 드라이버 누적 포인트 순위 | 25행 / 0.17초 |
| 5-1 — 원본 소속 팀 기준 팀별 순위 | 26행 / 0.11초 |
| 5-2 — 소속 팀 보완 후 팀별 순위 | 26행 / 0.10초 |

1\~5-1은 직접 작성한 최종 제출 SQL과 사용자 실행 결과를 기록했습니다. 5-2는 제공된 예시를 실행한 확장 실습으로 구분합니다. 미공유 중간 시도·오류 메시지는 만들지 않습니다. 원본 기준과 조회 단계 보완 결과를 모두 보존합니다.

- [ ] COUNT(\*)와 COUNT(컬럼)가 같은 조건 설명하기
- [ ] 전체 인원과 조건 충족 인원을 함께 세는 이유 설명하기
- [ ] CTE 안팎의 한 행 의미와 GROUP BY 필요 여부 설명하기
- [ ] 전체 순위와 팀 내 순위 차이 설명하기
- [ ] NULL 대체와 근거 있는 소속 보완의 차이 설명하기

다음 독립 재풀이는 아직 확인하지 않았습니다. 시험 주간에는 분량보다 SQLD 준비 일정에 맞춰 복습합니다.
</details>
</details>
