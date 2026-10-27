# Day 21 — F1 오스틴 결과·다중 경기 집계·CTE·윈도우 함수

[English](../en/day21.md) · [목차](../../README.ko.md)

<details>
<summary>🏎️ Day21 — F1 오스틴 결과·다중 경기 집계·CTE·윈도우 함수</summary>

# SQL 학습 기록 — Day 21

## 학습 개요

**환경:** MySQL / f1\_study
**범위:** 오스틴 공식 결과 조회·팀별 집계·18개 본 레이스 누적 포인트·CTE·RANK·PARTITION BY
**검증 근거:** MySQL 실행 결과표와 실행 시간. 아래 5개 쿼리는 최종 실행 SQL의 논리를 유지하고 줄바꿈을 정리했습니다. 이번 게시를 위해 문제 SQL을 다시 실행하지 않았습니다.

### 데이터 범위와 해석

- 2026년 오스틴까지 본 레이스 18개, 드라이버 결과 396행입니다. 취소된 경기·스프린트·예선·연습은 제외했습니다.
- 오스틴 세션 키는 11396입니다. 1·2번은 오스틴만, 3\~5번은 적재된 18개 경기 전체입니다.
- position은 저장된 공식 최종 순위입니다. NULL은 숫자 순위가 없음을 뜻합니다. 1번만 NULL 순위를 제외합니다.
- points는 본 레이스 점수이므로 합계를 공식 챔피언십 전체 점수로 해석하지 않습니다. RANK의 공동 순위 처리도 공식 동점 처리 규칙과 다릅니다.
- 40랩 조건은 이번 문제에 적용하지 않습니다. 공식 결과 조회·포인트 집계가 목적이며 평균 랩타임 비교 문제가 아닙니다.
- 기존 바쿠 단일 세션 쿼리는 이제 여러 경기가 섞일 수 있습니다. 경기별 통계는 세션 필터나 경기별 그룹 기준을 명시해야 합니다.

### 접속

일반 터미널에서 접속합니다.

```bash
mysql -u root -p
```

mysql> 화면에서 데이터베이스를 선택합니다.

```sql
USE f1_study;
```

<details>
<summary>📚 문제 1 — 오스틴 그랑프리 최종 결과</summary>

## 문제 1. 오스틴 그랑프리 최종 결과

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이고, race\_results의 한 행은 특정 세션의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 의미 |
| --- | --- | --- | --- |
| drivers | session\_key | INT | 세션 ID, NULL 불가 |
| drivers | driver\_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full\_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team\_name | VARCHAR(100) | 해당 경기의 소속 팀, NULL 허용 |
| race\_results | session\_key | INT | 세션 ID, NULL 불가 |
| race\_results | driver\_number | INT | 드라이버 번호, NULL 불가 |
| race\_results | position | INT | 공식 최종 순위, 숫자 순위가 없으면 NULL |
| race\_results | completed\_laps | INT | 공식 완료 랩 수 |
| race\_results | points | DECIMAL(8,2) | 해당 본 레이스 획득 포인트 |

두 테이블 모두 session\_key와 driver\_number의 조합으로 한 행을 구분합니다. 해당 조합으로 연결합니다. 현재 스냅샷의 결과 기록에는 completed\_laps와 points의 NULL이 없습니다. 이적한 드라이버는 경기마다 team\_name이 달라질 수 있습니다.

### 문제

오스틴의 공식 최종 순위와 드라이버 번호·이름·팀·완료 랩 수·포인트를 조회합니다.

### 조건

- 세션 11396만 조회합니다.
- position이 NULL인 행은 제외합니다.
- 0포인트·적은 완료 랩 수 기록도 포함합니다. 최소 랩·포인트 조건은 없습니다.
- 저장된 position을 사용하며 평균·포인트로 순위를 새로 계산하지 않습니다.
- 공식 순위 오름차순, 같으면 드라이버 번호 오름차순입니다.

### 출력 컬럼

결과 한 행은 오스틴에서 숫자 최종 순위가 있는 드라이버 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| race\_position | 공식 최종 순위 |
| driver\_number | 드라이버 번호 |
| full\_name | 이름 |
| team\_name | 팀 이름 |
| completed\_laps | 완료 랩 수 |
| points | 본 레이스 획득 포인트 |

### 가상 예시와 해설

가상 예시: DRIVER A가 공식 1위·56랩·25점이고 DRIVER B가 11위·55랩·0점이라면 두 행 모두 포함합니다.

### 최종 쿼리

```sql
SELECT
    position AS race_position,
    d.driver_number,
    d.full_name,
    d.team_name,
    r.completed_laps,
    r.points
FROM drivers d
JOIN race_results r
    ON r.session_key = d.session_key
   AND r.driver_number = d.driver_number
WHERE r.session_key = 11396
  AND r.position IS NOT NULL
ORDER BY race_position ASC, driver_number ASC;
```

### 실제 실행 결과

| race\_position | driver\_number | full\_name | team\_name | completed\_laps | points |
| --- | --- | --- | --- | --- | --- |
| 1 | 12 | Kimi ANTONELLI | Mercedes | 56 | 25.00 |
| 2 | 16 | Charles LECLERC | Ferrari | 56 | 18.00 |
| 3 | 3 | Max VERSTAPPEN | Red Bull Racing | 56 | 15.00 |
| 4 | 44 | Lewis HAMILTON | Ferrari | 56 | 12.00 |
| 5 | 1 | Lando NORRIS | McLaren | 56 | 10.00 |
| 6 | 6 | Isack HADJAR | Red Bull Racing | 56 | 8.00 |
| 7 | 81 | Oscar PIASTRI | McLaren | 56 | 6.00 |
| 8 | 63 | George RUSSELL | Mercedes | 56 | 4.00 |
| 9 | 30 | Liam LAWSON | Racing Bulls | 56 | 2.00 |
| 10 | 10 | Pierre GASLY | Alpine | 56 | 1.00 |
| 11 | 27 | Nico HULKENBERG | Audi | 56 | 0.00 |
| 12 | 41 | Arvid LINDBLAD | Racing Bulls | 55 | 0.00 |
| 13 | 5 | Gabriel BORTOLETO | Audi | 55 | 0.00 |
| 14 | 31 | Esteban OCON | Haas F1 Team | 55 | 0.00 |
| 15 | 18 | Lance STROLL | Aston Martin | 55 | 0.00 |
| 16 | 14 | Fernando ALONSO | Aston Martin | 55 | 0.00 |
| 17 | 23 | Alexander ALBON | Williams | 55 | 0.00 |
| 18 | 55 | Carlos SAINZ | Williams | 55 | 0.00 |
| 19 | 11 | Sergio PEREZ | Cadillac | 55 | 0.00 |

실행 결과: 19 rows in set (0.09 sec).

### 핵심 개념과 결과 해석

position AS race\_position은 기존 컬럼의 출력 이름만 바꿉니다. 집계나 순위 계산은 하지 않습니다. 여러 경기 합계를 조회하면 단일 경기 결과와 달라집니다. CTE 이름만으로 경기 필터가 생기지는 않습니다.
</details>

<details>
<summary>📚 문제 2 — 오스틴 그랑프리 팀별 성적</summary>

## 문제 2. 오스틴 그랑프리 팀별 성적

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이고, race\_results의 한 행은 특정 세션의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 의미 |
| --- | --- | --- | --- |
| drivers | session\_key | INT | 세션 ID, NULL 불가 |
| drivers | driver\_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full\_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team\_name | VARCHAR(100) | 해당 경기의 소속 팀, NULL 허용 |
| race\_results | session\_key | INT | 세션 ID, NULL 불가 |
| race\_results | driver\_number | INT | 드라이버 번호, NULL 불가 |
| race\_results | position | INT | 공식 최종 순위, 숫자 순위가 없으면 NULL |
| race\_results | completed\_laps | INT | 공식 완료 랩 수 |
| race\_results | points | DECIMAL(8,2) | 해당 본 레이스 획득 포인트 |

두 테이블 모두 session\_key와 driver\_number의 조합으로 한 행을 구분합니다. 해당 조합으로 연결합니다. 현재 스냅샷의 결과 기록에는 completed\_laps와 points의 NULL이 없습니다. 이적한 드라이버는 경기마다 team\_name이 달라질 수 있습니다.

### 문제

오스틴 결과를 팀별로 집계하여 드라이버 수·완료 랩 합계·포인트 합계를 조회합니다.

### 조건

- 세션 11396만 사용합니다.
- 최종 순위가 NULL인 결과도 포함합니다.
- 0포인트·적은 랩 수 기록도 포함하고 0포인트 팀도 출력합니다.
- 팀별 포인트 합계 내림차순, 같으면 팀 이름 오름차순입니다.
- CTE나 윈도우 함수는 필수가 아닙니다.

### 출력 컬럼

결과 한 행은 오스틴의 팀 하나입니다.

| 컬럼 | 의미 |
| --- | --- |
| team\_name | 팀 이름 |
| driver\_count | 팀의 결과 기록 수 |
| total\_laps | 완료 랩 합계 |
| total\_points | 해당 집계 단위의 본 레이스 포인트 합계 |

### 가상 예시와 해설

가상 예시: 한 팀의 두 드라이버가 각각 56랩·25점, 56랩·18점이면 driver\_count=2, total\_laps=112, total\_points=43.00입니다.

### 최종 쿼리

```sql
SELECT
    d.team_name,
    COUNT(*) AS driver_count,
    SUM(completed_laps) AS total_laps,
    SUM(points) AS total_points
FROM drivers d
JOIN race_results r
    ON r.session_key = d.session_key
   AND r.driver_number = d.driver_number
WHERE r.session_key = 11396
GROUP BY d.team_name
ORDER BY total_points DESC, team_name ASC;
```

### 실제 실행 결과

| team\_name | driver\_count | total\_laps | total\_points |
| --- | --- | --- | --- |
| Ferrari | 2 | 112 | 30.00 |
| Mercedes | 2 | 112 | 29.00 |
| Red Bull Racing | 2 | 112 | 23.00 |
| McLaren | 2 | 112 | 16.00 |
| Racing Bulls | 2 | 111 | 2.00 |
| Alpine | 2 | 91 | 1.00 |
| Aston Martin | 2 | 110 | 0.00 |
| Audi | 2 | 111 | 0.00 |
| Cadillac | 2 | 103 | 0.00 |
| Haas F1 Team | 2 | 79 | 0.00 |
| Williams | 2 | 110 | 0.00 |

실행 결과: 11 rows in set (0.10 sec).

### 핵심 개념과 결과 해석

드라이버별 결과를 팀별 한 행으로 합산하므로 GROUP BY와 SUM을 사용합니다. 두 테이블의 세션·드라이버 키가 유일하므로 연결된 행 수를 COUNT(\*)로 셉니다. 1번과 달리 순위 NULL 결과도 팀 집계에 포함합니다.
</details>

<details>
<summary>🧩 문제 3 — CTE로 드라이버별 본 레이스 포인트 합계</summary>

## 문제 3. CTE로 드라이버별 본 레이스 포인트 합계

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이고, race\_results의 한 행은 특정 세션의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 의미 |
| --- | --- | --- | --- |
| drivers | session\_key | INT | 세션 ID, NULL 불가 |
| drivers | driver\_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full\_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team\_name | VARCHAR(100) | 해당 경기의 소속 팀, NULL 허용 |
| race\_results | session\_key | INT | 세션 ID, NULL 불가 |
| race\_results | driver\_number | INT | 드라이버 번호, NULL 불가 |
| race\_results | position | INT | 공식 최종 순위, 숫자 순위가 없으면 NULL |
| race\_results | completed\_laps | INT | 공식 완료 랩 수 |
| race\_results | points | DECIMAL(8,2) | 해당 본 레이스 획득 포인트 |

두 테이블 모두 session\_key와 driver\_number의 조합으로 한 행을 구분합니다. 해당 조합으로 연결합니다. 현재 스냅샷의 결과 기록에는 completed\_laps와 points의 NULL이 없습니다. 이적한 드라이버는 경기마다 team\_name이 달라질 수 있습니다.

### 문제

CTE로 드라이버별 결과 기록 수와 포인트 합계를 계산한 뒤 합계 100 이상인 드라이버를 조회합니다.

### 조건

- 적재된 18개 본 레이스 전체를 사용합니다.
- CTE 이름은 driver\_totals이며 안쪽에서 드라이버별 집계를 계산합니다.
- 같은 드라이버의 이적 전후 기록을 합산합니다. 팀별로 나누지 않습니다.
- 0포인트·순위 NULL 경기 기록도 race\_count와 합계에 포함합니다.
- 100 이상 조건은 CTE 바깥에 작성합니다. 정확히 100도 포함합니다.
- 포인트 합계 내림차순, 같으면 드라이버 번호 오름차순입니다.

### 출력 컬럼

결과 한 행은 누적 본 레이스 포인트가 100 이상인 드라이버 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| driver\_number | 드라이버 번호 |
| full\_name | 이름 |
| race\_count | 해당 집계 단위의 본 레이스 결과 기록 수 |
| total\_points | 해당 집계 단위의 본 레이스 포인트 합계 |

### 가상 예시와 해설

가상 예시: 18개 결과에서 150점인 A와 16개 결과에서 100점인 B는 모두 포함됩니다. 경기 수 자체에 최소 조건은 없습니다.

### 최종 쿼리

```sql
WITH driver_totals AS (
    SELECT
        d.driver_number,
        d.full_name,
        COUNT(*) AS race_count,
        SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name
)
SELECT driver_number, full_name, race_count, total_points
FROM driver_totals
WHERE total_points >= 100
ORDER BY total_points DESC, driver_number ASC;
```

### 실제 실행 결과

| driver\_number | full\_name | race\_count | total\_points |
| --- | --- | --- | --- |
| 12 | Kimi ANTONELLI | 18 | 334.00 |
| 3 | Max VERSTAPPEN | 18 | 216.00 |
| 44 | Lewis HAMILTON | 18 | 214.00 |
| 63 | George RUSSELL | 18 | 208.00 |
| 16 | Charles LECLERC | 18 | 199.00 |
| 1 | Lando NORRIS | 18 | 178.00 |
| 81 | Oscar PIASTRI | 18 | 123.00 |
| 6 | Isack HADJAR | 15 | 105.00 |

실행 결과: 8 rows in set (0.00 sec).

### 핵심 개념과 결과 해석

CTE에서 이미 드라이버별 한 행으로 만들었으므로 바깥 GROUP BY는 불필요합니다. 바깥 WHERE는 만들어진 total\_points 컬럼을 선별합니다. 이번 MySQL에서 바깥 HAVING으로 같은 조건을 적용한 실행도 결과가 같았으며, WHERE로 변경한 것은 역할을 명확히 하는 작성 방식입니다.
</details>

<details>
<summary>🏁 문제 4 — 윈도우 함수로 본 레이스 누적 포인트 순위</summary>

## 문제 4. 윈도우 함수로 본 레이스 누적 포인트 순위

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이고, race\_results의 한 행은 특정 세션의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 의미 |
| --- | --- | --- | --- |
| drivers | session\_key | INT | 세션 ID, NULL 불가 |
| drivers | driver\_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full\_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team\_name | VARCHAR(100) | 해당 경기의 소속 팀, NULL 허용 |
| race\_results | session\_key | INT | 세션 ID, NULL 불가 |
| race\_results | driver\_number | INT | 드라이버 번호, NULL 불가 |
| race\_results | position | INT | 공식 최종 순위, 숫자 순위가 없으면 NULL |
| race\_results | completed\_laps | INT | 공식 완료 랩 수 |
| race\_results | points | DECIMAL(8,2) | 해당 본 레이스 획득 포인트 |

두 테이블 모두 session\_key와 driver\_number의 조합으로 한 행을 구분합니다. 해당 조합으로 연결합니다. 현재 스냅샷의 결과 기록에는 completed\_laps와 points의 NULL이 없습니다. 이적한 드라이버는 경기마다 team\_name이 달라질 수 있습니다.

### 문제

드라이버별 본 레이스 포인트 합계를 계산하고 전체 드라이버의 누적 포인트 순위를 조회합니다.

### 조건

- 적재된 18개 본 레이스 전체와 driver\_totals CTE를 사용합니다.
- 이적 전후 포인트는 드라이버별로 합산합니다.
- 100점 조건을 제거하고 0포인트와 순위 NULL 경기 결과도 포함합니다.
- RANK를 사용하며 포인트 합계만 내림차순으로 비교합니다.
- 같은 포인트는 공동 순위이며 경기 수·드라이버 번호는 순위 계산 기준에 넣지 않습니다.
- 최종 출력은 points\_rank 오름차순, 같으면 드라이버 번호 오름차순입니다.

### 출력 컬럼

결과 한 행은 드라이버 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| points\_rank | 전체 누적 포인트 순위 |
| driver\_number | 드라이버 번호 |
| full\_name | 이름 |
| race\_count | 해당 집계 단위의 본 레이스 결과 기록 수 |
| total\_points | 해당 집계 단위의 본 레이스 포인트 합계 |

### 가상 예시와 해설

가상 예시: A 150점, B·C 각 100점, D 0점이면 순위는 1·2·2·4입니다. 경기 수 차이는 공동 순위에 영향을 주지 않습니다.

### 최종 쿼리

```sql
WITH driver_totals AS (
    SELECT
        d.driver_number,
        d.full_name,
        COUNT(*) AS race_count,
        SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name
)
SELECT
    RANK() OVER (ORDER BY total_points DESC) points_rank,
    driver_number,
    full_name,
    race_count,
    total_points
FROM driver_totals
ORDER BY points_rank ASC, driver_number ASC;
```

### 실제 실행 결과

| points\_rank | driver\_number | full\_name | race\_count | total\_points |
| --- | --- | --- | --- | --- |
| 1 | 12 | Kimi ANTONELLI | 18 | 334.00 |
| 2 | 3 | Max VERSTAPPEN | 18 | 216.00 |
| 3 | 44 | Lewis HAMILTON | 18 | 214.00 |
| 4 | 63 | George RUSSELL | 18 | 208.00 |
| 5 | 16 | Charles LECLERC | 18 | 199.00 |
| 6 | 1 | Lando NORRIS | 18 | 178.00 |
| 7 | 81 | Oscar PIASTRI | 18 | 123.00 |
| 8 | 6 | Isack HADJAR | 15 | 105.00 |
| 9 | 30 | Liam LAWSON | 18 | 70.00 |
| 10 | 10 | Pierre GASLY | 18 | 40.00 |
| 11 | 41 | Arvid LINDBLAD | 18 | 37.00 |
| 12 | 43 | Franco COLAPINTO | 18 | 27.00 |
| 13 | 87 | Oliver BEARMAN | 18 | 19.00 |
| 14 | 27 | Nico HULKENBERG | 18 | 11.00 |
| 15 | 5 | Gabriel BORTOLETO | 18 | 10.00 |
| 16 | 14 | Fernando ALONSO | 18 | 7.00 |
| 16 | 31 | Esteban OCON | 18 | 7.00 |
| 16 | 55 | Carlos SAINZ | 18 | 7.00 |
| 19 | 23 | Alexander ALBON | 18 | 5.00 |
| 20 | 22 | Yuki TSUNODA | 3 | 1.00 |
| 21 | 11 | Sergio PEREZ | 18 | 0.00 |
| 21 | 18 | Lance STROLL | 18 | 0.00 |
| 21 | 77 | Valtteri BOTTAS | 18 | 0.00 |

실행 결과: 23 rows in set (0.01 sec).

### 핵심 개념과 결과 해석

실제 결과에서 7점인 세 명이 공동 16위이고 다음은 19위입니다. 0점 세 명도 공동 21위입니다. 순위 계산용 ORDER BY와 최종 출력 ORDER BY의 역할을 구분합니다.
</details>

<details>
<summary>🏁 문제 5 — 윈도우 함수로 팀별 드라이버 누적 포인트 순위</summary>

## 문제 5. 윈도우 함수로 팀별 드라이버 누적 포인트 순위

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이고, race\_results의 한 행은 특정 세션의 드라이버별 최종 결과입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | 의미 |
| --- | --- | --- | --- |
| drivers | session\_key | INT | 세션 ID, NULL 불가 |
| drivers | driver\_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full\_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team\_name | VARCHAR(100) | 해당 경기의 소속 팀, NULL 허용 |
| race\_results | session\_key | INT | 세션 ID, NULL 불가 |
| race\_results | driver\_number | INT | 드라이버 번호, NULL 불가 |
| race\_results | position | INT | 공식 최종 순위, 숫자 순위가 없으면 NULL |
| race\_results | completed\_laps | INT | 공식 완료 랩 수 |
| race\_results | points | DECIMAL(8,2) | 해당 본 레이스 획득 포인트 |

두 테이블 모두 session\_key와 driver\_number의 조합으로 한 행을 구분합니다. 해당 조합으로 연결합니다. 현재 스냅샷의 결과 기록에는 completed\_laps와 points의 NULL이 없습니다. 이적한 드라이버는 경기마다 team\_name이 달라질 수 있습니다.

### 문제

팀·드라이버별 본 레이스 결과 기록 수와 포인트 합계를 계산한 뒤 각 팀 안에서 포인트 순위를 조회합니다.

### 조건

- 적재된 18개 본 레이스 전체를 사용하고 CTE 이름은 team\_driver\_totals로 지정합니다.
- 이적한 드라이버는 팀별로 나누고 해당 팀 소속으로 얻은 포인트만 합산합니다.
- 0포인트와 순위 NULL 경기 기록을 포함하며 최소 경기 수·포인트 조건은 없습니다.
- 팀마다 RANK를 다시 시작하고 같은 포인트는 공동 순위입니다.
- 경기 수와 드라이버 번호는 순위 계산 기준에 넣지 않습니다.
- 팀 이름 → 팀 내 순위 → 드라이버 번호 오름차순으로 출력합니다.

### 출력 컬럼

결과 한 행은 한 팀에서의 드라이버 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| team\_name | 팀 이름 |
| team\_rank | 팀 내 누적 포인트 순위 |
| driver\_number | 드라이버 번호 |
| full\_name | 이름 |
| race\_count | 해당 집계 단위의 본 레이스 결과 기록 수 |
| total\_points | 해당 집계 단위의 본 레이스 포인트 합계 |

### 가상 예시와 해설

가상 예시: 이적한 B가 TEAM X에서 60점, TEAM Y에서 40점을 얻었다면 두 행으로 표시하고 각 팀 안에서 각각 순위를 계산합니다.

### 최종 쿼리

```sql
WITH team_driver_totals AS (
    SELECT
        d.team_name,
        d.driver_number,
        d.full_name,
        COUNT(*) AS race_count,
        SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.session_key = d.session_key
       AND r.driver_number = d.driver_number
    GROUP BY d.team_name, d.driver_number, d.full_name
)
SELECT
    team_name,
    RANK() OVER (
        PARTITION BY team_name
        ORDER BY total_points DESC
    ) AS team_rank,
    driver_number,
    full_name,
    race_count,
    total_points
FROM team_driver_totals
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### 실제 실행 결과

| team\_name | team\_rank | driver\_number | full\_name | race\_count | total\_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 18 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 18 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 18 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 18 | 0.00 |
| Audi | 1 | 27 | Nico HULKENBERG | 18 | 11.00 |
| Audi | 2 | 5 | Gabriel BORTOLETO | 18 | 10.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 18 | 0.00 |
| Cadillac | 1 | 77 | Valtteri BOTTAS | 18 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 18 | 214.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 18 | 199.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 18 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| McLaren | 1 | 1 | Lando NORRIS | 18 | 178.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 18 | 123.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 18 | 334.00 |
| Mercedes | 2 | 63 | George RUSSELL | 18 | 208.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 15 | 56.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 18 | 37.00 |
| Racing Bulls | 3 | 22 | Yuki TSUNODA | 3 | 1.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 18 | 216.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 15 | 105.00 |
| Red Bull Racing | 3 | 30 | Liam LAWSON | 3 | 14.00 |
| Williams | 1 | 55 | Carlos SAINZ | 18 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 18 | 5.00 |

실행 결과: 24 rows in set (0.10 sec).

### 핵심 개념과 결과 해석

실제 LAWSON은 Racing Bulls 15개 결과·56점, Red Bull Racing 3개 결과·14점으로 나뉩니다. 합계 70점은 4번 전체 드라이버 집계와 연결됩니다. Cadillac 두 드라이버는 0점으로 공동 1위입니다. 이적 후 팀 기록을 합쳐 한 팀의 점수로 잘못 계산하지 않도록 집계 단위를 구분합니다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — 조회·집계·이적·순위</summary>

## 저장된 값 조회와 새 계산 구분

position AS race\_position은 출력 이름을 바꿀 뿐 순위를 계산하지 않습니다. 이미 공식 결과가 있는 문제는 해당 값을 조회합니다. 여러 경기 포인트 합계와 팀별 순위처럼 새 지표가 필요할 때 집계·윈도우 함수를 사용합니다.

## CTE 안과 바깥의 역할

CTE 안에서 경기 기록을 드라이버별로 합산하면 한 행은 드라이버 한 명입니다. 바깥에서는 만들어진 total\_points를 조회·필터링·순위 계산에 사용합니다. 같은 기준으로 바깥 GROUP BY를 다시 할 필요가 없습니다.

## 이적을 합칠지 나눌지

전체 드라이버 합계는 이적 전후를 합칩니다. 팀별 기여도는 팀·드라이버별로 나눕니다. 4번은 23행, 5번은 24행이며 LAWSON의 팀 이동 기록이 분리되는 차이가 있습니다.

## 공동 순위와 표시 순서

RANK는 같은 포인트에 같은 순위를 주고 다음 순위를 건너뜁니다. OVER의 ORDER BY에는 점수만 넣고, 출력 동률 순서는 마지막 ORDER BY의 드라이버 번호로 지정합니다. PARTITION BY team\_name은 팀마다 순위를 새로 시작합니다.
</details>

<details>
<summary>🧠 실행 결과 요약·다음 복습</summary>

## 실행 결과 요약

| 문제 | 결과 |
| --- | --- |
| 1 | 오스틴 공식 순위 조회 19행 |
| 2 | 오스틴 팀별 집계 11행 |
| 3 | 본 레이스 누적 포인트 100 이상 드라이버 8행 |
| 4 | 전체 누적 포인트 순위 23행 |
| 5 | 팀·드라이버별 포인트 순위 24행 |

## 다음 복습 — 미실행

- [ ] 기존 순위 컬럼 조회와 RANK 계산을 구분
- [ ] 한 경기와 여러 경기의 집계 기준을 구분
- [ ] 드라이버별 합계와 팀·드라이버별 합계의 차이 설명
- [ ] CTE 바깥에서 GROUP BY 없이 WHERE를 사용하는 이유 설명
- [ ] 공동 순위와 최종 출력 정렬을 답 없이 작성
</details>
</details>
