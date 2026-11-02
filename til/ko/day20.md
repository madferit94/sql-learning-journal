# 🏎️ Day20 — F1 JOIN·CTE·윈도우 함수 기초

[English](../en/day20.md) · [목차](../../README.ko.md) · [검증 기록](../../docs/audit.ko.md)

<details>
<summary>🏎️ Day20 — F1 JOIN·CTE·윈도우 함수 기초</summary>

<b>재실행 범위:</b> 아래 SQL·결과는 바쿠 단일 세션 11377 기준의 과거 학습 기록입니다. 현재 f1_study에는 19경기가 있어 필터 없이 실행하면 다른 결과가 나옵니다. 이번 재검증은 원본 쿼리를 바꾸지 않고 세션 11377만 노출하는 별도 조회 환경에서 수행했습니다. 직접 재실행할 때는 모든 원본 테이블의 세션을 바쿠로 제한해야 합니다.

# SQL 학습 기록 — Day 20

## 학습 개요

<b>환경:</b> MySQL / f1_study
<b>사용 테이블:</b> drivers, laps
<b>대상:</b> 당시 바쿠 단일 세션 11377
<b>범위:</b> 복합 JOIN 키, CTE, 대상 드라이버 수 계산, 전체 순위, 팀 내 순위. 이어 진행한 5문제를 한 세션으로 묶었습니다.
<b>검증 근거:</b> 사용자 제출 SQL과 공유한 MySQL 실행 결과.

### 접속

일반 터미널:

```bash
mysql -u root -p
```

mysql> 화면:

```sql
USE f1_study;
```

### 데이터와 한 행의 의미

drivers는 특정 세션의 드라이버 한 명, laps는 해당 드라이버의 랩 하나입니다.

| 테이블 | 컬럼 | 자료형 | NULL 허용 | 의미 |
| --- | --- | --- | --- | --- |
| drivers | session_key | INT | 불가 | 세션 ID |
| drivers | driver_number | INT | 불가 | 드라이버 번호 |
| drivers | full_name | VARCHAR(100) | 허용 | 이름 |
| drivers | team_name | VARCHAR(100) | 허용 | 팀 |
| laps | session_key | INT | 불가 | 세션 ID |
| laps | driver_number | INT | 불가 | 드라이버 번호 |
| laps | lap_number | INT | 불가 | 랩 번호 |
| laps | lap_duration | DECIMAL(12,3) | 허용 | 랩타임(초), NULL은 미기록 |

같은 세션·같은 드라이버의 정보에 여러 랩이 연결됩니다. 두 키는 session_key와 driver_number입니다.

### 왜 40랩 이상을 기준으로 사용했는가?

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 이번 학습에서는 <b>랩타임이 기록된 랩 40개 이상</b>을 선정 조건으로 사용했습니다. 바쿠의 정규 레이스는 51랩입니다. [F1 공식 서킷 정보](https://www.formula1.com/en/racing/2026/azerbaijan)

- 40랩은 학습용 임계값이며 F1 공식 기준이나 통계적으로 검증된 기준이 아닙니다.
- COUNT(lap_duration)은 NULL이 아닌 기록 수입니다. 공식 완주 랩 수와 항상 같다고 단정하지 않습니다.
- 40개 이상이어도 타이어, 피트스톱, 세이프티카, 주행 상황 차이가 남으므로 비교 가능성이 보장되지는 않습니다.
- 결과는 <b>선정된 드라이버의 평균 랩타임 순위</b>이며 실제 경기 최종 순위나 실력 순위가 아닙니다.
- 40랩 조건을 제거하면 기록이 적은 드라이버도 평균 비교에 포함될 수 있지만, 평균 순위가 공식 결과로 바뀌는 것은 아닙니다.

<details>
<summary>📚 문제 1 — JOIN 복습·드라이버별 랩 통계</summary>

## 문제 1. 드라이버별 평균 랩타임

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이며, laps의 한 행은 해당 드라이버의 랩 하나입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | NULL 허용 | 의미 |
| --- | --- | --- | --- | --- |
| drivers | session_key | INT | 불가 | 세션 ID |
| drivers | driver_number | INT | 불가 | 드라이버 번호 |
| drivers | full_name | VARCHAR(100) | 허용 | 이름 |
| drivers | team_name | VARCHAR(100) | 허용 | 팀 |
| laps | session_key | INT | 불가 | 세션 ID |
| laps | driver_number | INT | 불가 | 드라이버 번호 |
| laps | lap_number | INT | 불가 | 랩 번호 |
| laps | lap_duration | DECIMAL(12,3) | 허용 | 랩타임(초), NULL은 미기록 |

drivers의 기본키는 session_key + driver_number, laps의 기본키는 session_key + driver_number + lap_number입니다. 세션 ID와 드라이버 번호로 연결하는 일대다 관계입니다. 당시 학습 스냅샷은 세션 11377 하나였습니다. NULL 랩타임은 0초가 아니라 미기록입니다.

### 문제

두 테이블을 연결하여 랩타임이 기록된 랩이 40개 이상인 드라이버의 이름·팀·기록된 랩 수·평균 랩타임을 조회합니다.

### 조건

- 같은 세션의 같은 드라이버끼리 연결합니다.
- NULL 랩타임은 랩 수와 평균 계산에서 제외합니다. 정확히 40개도 포함합니다.
- 평균은 소수점 둘째 자리까지 반올림합니다.
- 출력된 평균 오름차순, 같으면 드라이버 번호 오름차순입니다.

### 40랩 기준의 이유

기록 수가 적은 드라이버를 제외하는 학습용 선정 조건입니다. 공식 기준이나 실력 판정 기준은 아닙니다. 세부 해석 한계는 Day20 학습 개요와 같습니다.

### 출력 컬럼

결과 한 행은 대상 드라이버 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| team_name | 팀 |
| timed_lap_count | NULL이 아닌 랩타임 기록 수 |
| avg_lap_duration | 평균 랩타임(초), 표시값 소수점 둘째 자리 |

### 가상 출력 예시

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- | --- |
| 10 | DRIVER A | TEAM X | 45 | 108.25 |
| 20 | DRIVER B | TEAM Y | 40 | 109.10 |

DRIVER B는 정확히 40개이므로 포함됩니다.

### 첫 제출과 수정 이유

처음에는 ON l.driver_number = d.driver_number만 작성했습니다. 현재 두 테이블에 같은 세션 하나만 있어 출력은 맞았습니다. 여러 세션이 적재되면 다른 경기의 같은 번호 정보까지 연결될 수 있어 세션 키를 추가했습니다.

### 최종 제출 쿼리

```sql
SELECT
    d.driver_number,
    d.full_name,
    d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(lap_duration), 2) AS avg_lap_duration
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY d.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;
```

### 실제 결과

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- | --- |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 |
| 16 | Charles LECLERC | Ferrari | 51 | 115.62 |
| 12 | Kimi ANTONELLI | Mercedes | 51 | 115.63 |
| 44 | Lewis HAMILTON | Ferrari | 51 | 115.78 |
| 31 | Esteban OCON | Haas F1 Team | 51 | 115.95 |
| 41 | Arvid LINDBLAD | Racing Bulls | 51 | 115.95 |
| 87 | Oliver BEARMAN | Haas F1 Team | 51 | 115.97 |
| 55 | Carlos SAINZ | Williams | 51 | 115.98 |
| 27 | Nico HULKENBERG | Audi | 51 | 116.00 |
| 5 | Gabriel BORTOLETO | Audi | 51 | 116.01 |
| 30 | Liam LAWSON | Racing Bulls | 51 | 116.01 |
| 81 | Oscar PIASTRI | McLaren | 51 | 116.06 |
| 11 | Sergio PEREZ | Cadillac | 51 | 116.16 |
| 77 | Valtteri BOTTAS | Cadillac | 49 | 116.94 |

실행 결과: 16 rows in set (0.00 sec).

### 핵심 개념

JOIN 키와 집계 기준은 별개입니다. 여러 경기 데이터에서는 JOIN에 두 키가 필요하며, 경기별 통계라면 그룹 기준에도 세션을 포함해야 합니다. 이번은 한 세션입니다.
</details>

<details>
<summary>🧩 문제 2 — CTE로 드라이버별 통계 조회</summary>

## 문제 2. CTE로 드라이버별 랩 통계 조회

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이며, laps의 한 행은 해당 드라이버의 랩 하나입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | NULL 허용 | 의미 |
| --- | --- | --- | --- | --- |
| drivers | session_key | INT | 불가 | 세션 ID |
| drivers | driver_number | INT | 불가 | 드라이버 번호 |
| drivers | full_name | VARCHAR(100) | 허용 | 이름 |
| drivers | team_name | VARCHAR(100) | 허용 | 팀 |
| laps | session_key | INT | 불가 | 세션 ID |
| laps | driver_number | INT | 불가 | 드라이버 번호 |
| laps | lap_number | INT | 불가 | 랩 번호 |
| laps | lap_duration | DECIMAL(12,3) | 허용 | 랩타임(초), NULL은 미기록 |

drivers의 기본키는 session_key + driver_number, laps의 기본키는 session_key + driver_number + lap_number입니다. 세션 ID와 드라이버 번호로 연결하는 일대다 관계입니다. 당시 학습 스냅샷은 세션 11377 하나였습니다. NULL 랩타임은 0초가 아니라 미기록입니다.

### 문제

드라이버별 랩 통계를 driver_stats라는 중간 결과로 만든 뒤 40랩 이상인 드라이버를 조회합니다.

### 조건

- 두 키로 JOIN하고 CTE에서 드라이버별 기록된 랩 수와 평균을 계산합니다.
- NULL은 기록 수·평균에서 제외하며 정확히 40개도 포함합니다.
- 40개 이상 조건은 CTE 바깥에 작성합니다.
- 평균은 소수점 둘째 자리까지 표시합니다.
- 출력된 평균 오름차순, 같으면 드라이버 번호 오름차순입니다.

### 40랩 기준의 이유

일정량 이상의 기록을 가진 드라이버를 선정하는 학습용 조건입니다. 공식 경기 성적·실력 비교를 보장하지 않습니다.

### 출력 컬럼

한 행은 대상 드라이버 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| team_name | 팀 |
| timed_lap_count | NULL이 아닌 랩타임 기록 수 |
| avg_lap_duration | 평균 랩타임(초), 표시값 소수점 둘째 자리 |

### 가상 출력 예시

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- | --- |
| 10 | DRIVER A | TEAM X | 45 | 108.25 |
| 20 | DRIVER B | TEAM Y | 40 | 109.10 |

45개와 40개 모두 조건을 만족합니다. 실제 출력이 아닌 형식 설명입니다.

### 첫 시도에서 점검한 부분

CTE 바깥에서는 CTE의 SELECT 목록에 포함된 컬럼만 사용할 수 있습니다. 안쪽에서 집계하고 바깥에서 집계 결과를 조회합니다.

### 최종 제출 쿼리

```sql
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(lap_duration) AS timed_lap_count,
        ROUND(AVG(lap_duration), 2) AS avg_lap_duration
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY driver_number, full_name, team_name
)
SELECT
    driver_number,
    full_name,
    team_name,
    timed_lap_count,
    avg_lap_duration
FROM driver_stats
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;
```

### 실제 결과

사용자가 공유한 16행은 문제 1과 동일합니다. 중복을 줄여 아래에는 실제 앞 3행만 표시합니다.

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- | --- |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 |

실행 결과: 16 rows in set (0.02 sec).

### 바깥 HAVING은 오답인가?

이번 MySQL의 바깥 HAVING은 실행 가능하고 결과도 같습니다. 바깥에서는 새로 집계하지 않고 이미 만들어진 컬럼으로 선별하므로 WHERE timed_lap_count >= 40이 역할을 더 명확하게 나타냅니다.

### 반올림 위치

이 문제는 평균을 그대로 출력하므로 안쪽 반올림이 가능합니다. 평균을 재집계하거나 원래 평균으로 순위를 매길 때는 중간 정밀도를 유지해야 합니다.
</details>

<details>
<summary>🧩 문제 3 — CTE로 대상 드라이버 수 계산</summary>

## 문제 3. 조건을 만족하는 드라이버 수

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이며, laps의 한 행은 해당 드라이버의 랩 하나입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | NULL 허용 | 의미 |
| --- | --- | --- | --- | --- |
| drivers | session_key | INT | 불가 | 세션 ID |
| drivers | driver_number | INT | 불가 | 드라이버 번호 |
| drivers | full_name | VARCHAR(100) | 허용 | 이름 |
| drivers | team_name | VARCHAR(100) | 허용 | 팀 |
| laps | session_key | INT | 불가 | 세션 ID |
| laps | driver_number | INT | 불가 | 드라이버 번호 |
| laps | lap_number | INT | 불가 | 랩 번호 |
| laps | lap_duration | DECIMAL(12,3) | 허용 | 랩타임(초), NULL은 미기록 |

drivers의 기본키는 session_key + driver_number, laps의 기본키는 session_key + driver_number + lap_number입니다. 세션 ID와 드라이버 번호로 연결하는 일대다 관계입니다. 당시 학습 스냅샷은 세션 11377 하나였습니다. NULL 랩타임은 0초가 아니라 미기록입니다.

### 문제

기록된 랩이 40개 이상인 드라이버가 몇 명인지 CTE로 조회합니다.

### 조건

- 두 키로 JOIN하고 driver_stats CTE에서 드라이버별 기록 수를 계산합니다.
- NULL은 기록 수에서 제외합니다. 정확히 40개도 포함합니다.
- 선별 조건은 바깥 조회에 작성합니다.
- 최종 결과는 드라이버 수 한 행, 대상이 없으면 0입니다. 정렬 조건은 없습니다.

### 40랩 기준의 이유

기록 수가 일정량 이상인 드라이버를 고르는 학습용 조건입니다. 이 문제는 대상 드라이버 수를 셀 뿐 경기 순위를 계산하지 않습니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| driver_count | 조건을 만족한 드라이버 수 |

### 가상 예시

다음은 원본 랩이 아닌 설명용 집계표입니다.

| 드라이버 | 기록된 랩 수 |
| --- | --- |
| A | 45 |
| B | 40 |
| C | 39 |

A와 B를 포함하여 최종 출력은 다음과 같습니다.

| driver_count |
| --- |
| 2 |

### 최종 제출 쿼리

```sql
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(l.lap_duration) AS timed_lap_count
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name, d.team_name
)
SELECT COUNT(timed_lap_count) AS driver_count
FROM driver_stats
WHERE timed_lap_count >= 40;
```

### 실제 결과

| driver_count |
| --- |
| 16 |

실행 결과: 1 row in set (0.02 sec).

### 핵심 개념

안쪽은 드라이버 한 명당 한 행을 만듭니다. 바깥은 조건을 통과한 행 수를 세므로 드라이버 수입니다. timed_lap_count는 안쪽 COUNT가 만든 값이라 NULL이 없어, 이번 COUNT(timed_lap_count)와 COUNT(\*)는 같습니다.
</details>

<details>
<summary>🏁 문제 4 — 윈도우 함수·전체 RANK</summary>

## 문제 4. 드라이버별 평균 랩타임 순위

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이며, laps의 한 행은 해당 드라이버의 랩 하나입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | NULL 허용 | 의미 |
| --- | --- | --- | --- | --- |
| drivers | session_key | INT | 불가 | 세션 ID |
| drivers | driver_number | INT | 불가 | 드라이버 번호 |
| drivers | full_name | VARCHAR(100) | 허용 | 이름 |
| drivers | team_name | VARCHAR(100) | 허용 | 팀 |
| laps | session_key | INT | 불가 | 세션 ID |
| laps | driver_number | INT | 불가 | 드라이버 번호 |
| laps | lap_number | INT | 불가 | 랩 번호 |
| laps | lap_duration | DECIMAL(12,3) | 허용 | 랩타임(초), NULL은 미기록 |

drivers의 기본키는 session_key + driver_number, laps의 기본키는 session_key + driver_number + lap_number입니다. 세션 ID와 드라이버 번호로 연결하는 일대다 관계입니다. 당시 학습 스냅샷은 세션 11377 하나였습니다. NULL 랩타임은 0초가 아니라 미기록입니다.

### 새 문법: RANK

```sql
RANK() OVER (ORDER BY avg_lap_duration ASC)
```

행을 유지하면서 순위를 붙입니다. 같은 값은 공동 순위이며 공동 2위가 두 명이면 다음은 4위입니다.

### 문제

기록된 랩이 40개 이상인 드라이버들에게 평균 랩타임이 짧은 순서로 순위를 부여합니다.

### 조건

- 두 키로 JOIN하고 driver_stats CTE를 사용합니다.
- NULL은 기록 수·평균에서 제외합니다. 정확히 40개도 포함합니다.
- CTE의 평균은 반올림하지 않습니다.
- 바깥에서 40개 이상인 드라이버만 선정하여 반올림 전 평균으로 RANK를 계산합니다.
- 출력 평균만 소수점 둘째 자리까지 반올림합니다.
- 최종 결과는 순위 오름차순, 같으면 드라이버 번호 오름차순입니다.

### 40랩 기준과 해석 한계

일정량 이상의 기록을 가진 드라이버끼리 비교하려는 학습용 선정 조건이며, 공식 경기 최종 순위·실력 순위가 아닙니다.

### 출력 컬럼

한 행은 대상 드라이버 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| team_name | 팀 |
| timed_lap_count | NULL이 아닌 랩타임 기록 수 |
| avg_lap_duration | 평균 랩타임(초), 표시값 소수점 둘째 자리 |
| lap_rank | 반올림 전 평균을 기준으로 한 순위 |

### 가상 출력 예시

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration | lap_rank |
| --- | --- | --- | --- | --- | --- |
| 10 | DRIVER A | TEAM X | 45 | 108.25 | 1 |
| 20 | DRIVER B | TEAM Y | 40 | 109.10 | 2 |
| 30 | DRIVER C | TEAM Z | 48 | 109.10 | 2 |
| 40 | DRIVER D | TEAM X | 42 | 110.35 | 4 |

B와 C는 반올림 전 평균도 같다고 가정한 예시입니다.

### 최종 제출 쿼리

```sql
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(lap_duration) AS timed_lap_count,
        AVG(lap_duration) AS avg_lap_duration
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name, d.team_name
)
SELECT
    driver_number,
    full_name,
    team_name,
    timed_lap_count,
    ROUND(avg_lap_duration, 2) AS avg_lap_duration,
    RANK() OVER (
        ORDER BY avg_lap_duration ASC
    ) AS lap_rank
FROM driver_stats
WHERE timed_lap_count >= 40
ORDER BY lap_rank ASC, driver_number ASC;
```

### 실제 결과

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration | lap_rank |
| --- | --- | --- | --- | --- | --- |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 | 1 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 | 2 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 | 3 |
| 16 | Charles LECLERC | Ferrari | 51 | 115.62 | 4 |
| 12 | Kimi ANTONELLI | Mercedes | 51 | 115.63 | 5 |
| 44 | Lewis HAMILTON | Ferrari | 51 | 115.78 | 6 |
| 41 | Arvid LINDBLAD | Racing Bulls | 51 | 115.95 | 7 |
| 31 | Esteban OCON | Haas F1 Team | 51 | 115.95 | 8 |
| 87 | Oliver BEARMAN | Haas F1 Team | 51 | 115.97 | 9 |
| 55 | Carlos SAINZ | Williams | 51 | 115.98 | 10 |
| 27 | Nico HULKENBERG | Audi | 51 | 116.00 | 11 |
| 30 | Liam LAWSON | Racing Bulls | 51 | 116.01 | 12 |
| 5 | Gabriel BORTOLETO | Audi | 51 | 116.01 | 13 |
| 81 | Oscar PIASTRI | McLaren | 51 | 116.06 | 14 |
| 11 | Sergio PEREZ | Cadillac | 51 | 116.16 | 15 |
| 77 | Valtteri BOTTAS | Cadillac | 49 | 116.94 | 16 |

실행 결과: 16 rows in set (0.01 sec).

### 수정 및 이해 점검

첫 실행에서도 순위 계산은 맞았습니다. 이후 평균 출력 컬럼의 별칭과 최종 ORDER BY를 추가했습니다.

| 위치 | 역할 |
| --- | --- |
| OVER 안 ORDER BY | 순위를 계산하는 기준 |
| 쿼리 마지막 ORDER BY | 결과 행을 보여주는 순서 |

마지막 ORDER BY가 없으면 최종 출력 순서를 보장하지 않습니다. LINDBLAD와 OCON은 표시 평균이 모두 115.95지만 반올림 전 값이 달라 각각 7위와 8위입니다.
</details>

<details>
<summary>🏁 문제 5 — 윈도우 함수·PARTITION BY 팀 내 순위</summary>

## 문제 5. 팀 안에서 드라이버 순위 매기기

### 테이블 설명

drivers의 한 행은 특정 세션에 참가한 드라이버 한 명이며, laps의 한 행은 해당 드라이버의 랩 하나입니다. 필요한 컬럼 일부입니다.

| 테이블 | 컬럼 | 자료형 | NULL 허용 | 의미 |
| --- | --- | --- | --- | --- |
| drivers | session_key | INT | 불가 | 세션 ID |
| drivers | driver_number | INT | 불가 | 드라이버 번호 |
| drivers | full_name | VARCHAR(100) | 허용 | 이름 |
| drivers | team_name | VARCHAR(100) | 허용 | 팀 |
| laps | session_key | INT | 불가 | 세션 ID |
| laps | driver_number | INT | 불가 | 드라이버 번호 |
| laps | lap_number | INT | 불가 | 랩 번호 |
| laps | lap_duration | DECIMAL(12,3) | 허용 | 랩타임(초), NULL은 미기록 |

drivers의 기본키는 session_key + driver_number, laps의 기본키는 session_key + driver_number + lap_number입니다. 세션 ID와 드라이버 번호로 연결하는 일대다 관계입니다. 당시 학습 스냅샷은 세션 11377 하나였습니다. NULL 랩타임은 0초가 아니라 미기록입니다.

### 새 문법: PARTITION BY

```sql
RANK() OVER (
    PARTITION BY team_name
    ORDER BY avg_lap_duration ASC
)
```

같은 팀끼리 나누어 계산합니다. 행은 유지되고 팀이 달라지면 순위가 다시 1위부터 시작합니다.

### 문제

기록된 랩이 40개 이상인 드라이버들을 대상으로 팀 내 평균 랩타임 순위를 조회합니다.

### 조건

- 두 키로 JOIN하고 driver_stats CTE를 사용합니다.
- NULL은 기록 수·평균에서 제외합니다. 정확히 40개도 포함합니다.
- CTE 안의 평균은 반올림하지 않습니다.
- 40개 이상인 드라이버만 팀 내 비교 대상으로 삼습니다.
- 팀 안에서 반올림 전 평균이 짧을수록 높은 순위이며 RANK로 공동 순위를 처리합니다.
- 출력 평균만 소수점 둘째 자리까지 반올림합니다.
- 팀 이름 → 팀 내 순위 → 드라이버 번호 오름차순으로 정렬합니다.

### 40랩 기준과 해석 한계

전체 참가 드라이버가 아니라 기록 수 조건을 통과한 드라이버 사이의 순위입니다. 팀의 모든 참가자나 공식 경기 성적을 비교한 결과가 아닙니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| team_name | 팀 |
| timed_lap_count | NULL이 아닌 랩타임 기록 수 |
| avg_lap_duration | 평균 랩타임(초), 표시값 소수점 둘째 자리 |
| team_rank | 선정된 드라이버 사이의 팀 내 순위 |

### 가상 출력 예시

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration | team_rank |
| --- | --- | --- | --- | --- | --- |
| 10 | DRIVER A | TEAM X | 45 | 108.25 | 1 |
| 20 | DRIVER B | TEAM X | 40 | 109.10 | 2 |
| 30 | DRIVER C | TEAM Y | 48 | 107.50 | 1 |
| 40 | DRIVER D | TEAM Y | 42 | 110.35 | 2 |

A와 C가 각각 소속 팀에서 1위입니다.

### 최종 제출 쿼리

```sql
WITH driver_stats AS (
    SELECT
        d.driver_number,
        d.full_name,
        d.team_name,
        COUNT(lap_duration) AS timed_lap_count,
        AVG(lap_duration) AS avg_lap_duration
    FROM drivers d
    JOIN laps l
        ON l.session_key = d.session_key
       AND l.driver_number = d.driver_number
    GROUP BY d.driver_number, d.full_name, d.team_name
)
SELECT
    driver_number,
    full_name,
    team_name,
    timed_lap_count,
    ROUND(avg_lap_duration, 2) AS avg_lap_duration,
    RANK() OVER (
        PARTITION BY team_name
        ORDER BY avg_lap_duration ASC
    ) AS team_rank
FROM driver_stats
WHERE timed_lap_count >= 40
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### 실제 결과

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration | team_rank |
| --- | --- | --- | --- | --- | --- |
| 27 | Nico HULKENBERG | Audi | 51 | 116.00 | 1 |
| 5 | Gabriel BORTOLETO | Audi | 51 | 116.01 | 2 |
| 11 | Sergio PEREZ | Cadillac | 51 | 116.16 | 1 |
| 77 | Valtteri BOTTAS | Cadillac | 49 | 116.94 | 2 |
| 16 | Charles LECLERC | Ferrari | 51 | 115.62 | 1 |
| 44 | Lewis HAMILTON | Ferrari | 51 | 115.78 | 2 |
| 31 | Esteban OCON | Haas F1 Team | 51 | 115.95 | 1 |
| 87 | Oliver BEARMAN | Haas F1 Team | 51 | 115.97 | 2 |
| 81 | Oscar PIASTRI | McLaren | 51 | 116.06 | 1 |
| 63 | George RUSSELL | Mercedes | 51 | 115.34 | 1 |
| 12 | Kimi ANTONELLI | Mercedes | 51 | 115.63 | 2 |
| 41 | Arvid LINDBLAD | Racing Bulls | 51 | 115.95 | 1 |
| 30 | Liam LAWSON | Racing Bulls | 51 | 116.01 | 2 |
| 3 | Max VERSTAPPEN | Red Bull Racing | 51 | 115.35 | 1 |
| 6 | Isack HADJAR | Red Bull Racing | 51 | 115.55 | 2 |
| 55 | Carlos SAINZ | Williams | 51 | 115.98 | 1 |

실행 결과: 16 rows in set (0.06 sec).

### 결과 해석

McLaren과 Williams는 랩타임이 기록된 랩이 40개 이상인 드라이버가 각각 한 명이므로 팀 내 1위만 표시됩니다. 팀에 참가한 드라이버가 한 명뿐이라는 뜻은 아닙니다.

이 결과는 전체 참가자가 아니라 40랩 조건을 만족한 드라이버 사이의 팀 내 평균 랩타임 순위입니다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — JOIN·CTE·순위·선정 기준</summary>

## JOIN과 집계 기준은 별개

현재는 한 세션이라 번호만 연결해도 결과가 같았지만, 다중 세션 데이터는 같은 세션·같은 드라이버로 연결해야 합니다. 경기별 집계를 원하면 그룹 기준에도 세션을 포함합니다.

## CTE 한 행은 드라이버 한 명

원본 랩들을 집계한 중간 결과를 바깥에서 조회·선별·개수 계산·순위 계산에 사용했습니다.

## 반올림

표시만 할 때는 안쪽 반올림도 가능합니다. 원래 평균으로 순위를 계산하거나 평균을 다시 집계할 때는 중간 정밀도를 유지합니다.

## 순위 계산과 출력 정렬

OVER 안 ORDER BY는 순위의 계산 기준입니다. 마지막 ORDER BY는 결과의 출력 순서입니다.

## 비교 대상과 순위 의미

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 이번 학습에서는 <b>랩타임이 기록된 랩 40개 이상</b>을 선정 조건으로 사용했습니다. 바쿠의 정규 레이스는 51랩입니다. [F1 공식 서킷 정보](https://www.formula1.com/en/racing/2026/azerbaijan)

- 40랩은 학습용 임계값이며 F1 공식 기준이나 통계적으로 검증된 기준이 아닙니다.
- COUNT(lap_duration)은 NULL이 아닌 기록 수입니다. 공식 완주 랩 수와 항상 같다고 단정하지 않습니다.
- 40개 이상이어도 타이어, 피트스톱, 세이프티카, 주행 상황 차이가 남으므로 비교 가능성이 보장되지는 않습니다.
- 결과는 <b>선정된 드라이버의 평균 랩타임 순위</b>이며 실제 경기 최종 순위나 실력 순위가 아닙니다.
- 40랩 조건을 제거하면 기록이 적은 드라이버도 평균 비교에 포함될 수 있지만, 평균 순위가 공식 결과로 바뀌는 것은 아닙니다.
현재 PARTITION BY team_name을 유지한 채 40랩 조건만 빼면 팀 내 평균 순위입니다. 전체 평균 순위를 원하면 팀 분할도 제거해야 하며, 어느 경우든 공식 최종 순위와는 다릅니다.
</details>

<details>
<summary>🧠 학습 회고·검증 범위·재풀이</summary>

## 문제별 실행 결과

| 문제 | 실행 결과 |
| --- | --- |
| 1 | 드라이버별 랩 통계 16행 |
| 2 | CTE를 이용한 드라이버별 랩 통계 16행 |
| 3 | 조건을 만족한 드라이버 16명 |
| 4 | 전체 평균 랩타임 순위 16행 |
| 5 | 팀 내 평균 랩타임 순위 16행 |

실제 출력에는 공동 순위가 없습니다. 공동 순위의 동작은 가상 예시와 구분합니다.

## 다음 복습 — 미실행

- [ ] 두 JOIN 키가 필요한 이유 설명
- [ ] CTE의 한 행이 무엇인지 설명
- [ ] 순위 계산용 정렬과 출력 정렬 구분
- [ ] 전체 순위와 팀 내 순위를 답 없이 작성
- [ ] 40랩 기준의 목적과 해석 한계 설명
- [ ] 반올림 전후 값에 따라 순위가 달라질 수 있음을 설명
</details>
</details>
