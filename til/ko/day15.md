# 🏎️ Day15 — Baku F1 2일차·조건부 집계·팀 통계·서브쿼리

[English](../en/day15.md) · [목차](../../README.ko.md) · [검증 기록](../../docs/audit.ko.md)

<details>
<summary>🏎️ Day15 — Baku F1 2일차·조건부 집계·팀 통계·서브쿼리</summary>

<b>재실행 범위:</b> 아래 SQL·결과는 바쿠 단일 세션 11377 기준의 과거 학습 기록입니다. 현재 f1_study에는 19경기가 있어 필터 없이 실행하면 다른 결과가 나옵니다. 이번 재검증은 원본 쿼리를 바꾸지 않고 세션 11377만 노출하는 별도 조회 환경에서 수행했습니다. 직접 재실행할 때는 모든 원본 테이블의 세션을 바쿠로 제한해야 합니다.

# SQL 학습 기록 — Day 15

## 학습 개요

<b>환경:</b> MySQL / f1_study / laps·drivers

<b>범위:</b> 조건부 COUNT·비율·복합 JOIN·팀별 AVG/MIN·서브쿼리 COUNT/AVG, 5문제.

<b>검증 근거:</b> 사용자가 직접 실행해 공유한 MySQL 출력.

### 접속 — 매번 문제 앞에 안내

일반 터미널에서 실행:

```bash
mysql -u root -p
```

비밀번호 입력 후 mysql> 화면에서 실행:

```sql
USE f1_study;
SHOW TABLES;
```

이미 mysql> 화면이면 USE부터 시작한다. 터미널 % 화면에는 SQL을 입력하지 않는다.

### 데이터 설명

<b>laps — 한 행은 특정 세션에서 드라이버 한 명의 한 랩입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| lap_number | INT | 해당 드라이버의 랩 순번 |
| lap_duration | DECIMAL(12,3) | 랩타임(초), 기록이 없으면 NULL |

당시 학습 스냅샷에는 바쿠 세션 하나만 있었습니다. NULL은 0초가 아니라 시간 기록이 없는 상태입니다.

<b>drivers — 한 행은 세션에 참가한 드라이버 한 명입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| full_name | VARCHAR(100) | 드라이버 이름 |
| team_name | VARCHAR(100) | 팀 이름 |

같은 session_key와 driver_number를 가진 행끼리 같은 세션의 같은 드라이버입니다.

laps의 기본키는 session_key + driver_number + lap_number, drivers의 기본키는 session_key + driver_number다. drivers 한 행에 여러 laps 행이 연결된다.

전체 laps 983행 중 lap_duration 기록 976행, NULL 7행. drivers 22행. lap_details 뷰와 stints 테이블은 오늘 문제에 사용하지 않았다.

원본: [바쿠 프로젝트 고정 스냅샷](https://github.com/madferit94/all-sports-analytics/tree/c1e22c8f1d0f14192f92159d59b7b8f12a307ef5/f1/baku-2026). 임계값 109초·110초는 SQL 연습 기준이며 공식 성능 기준이 아니다. 전체 랩 평균에 피트·세이프티카·타이어·교통 등 맥락이 섞일 수 있어 실력 순위로 단정하지 않는다.

<details>
<summary>📚 문제 1\~3 — 조건부 집계·비율·팀별 JOIN</summary>

## 문제 1. 드라이버별 109초 미만 랩 수

### 선정 기준의 이유와 해석 한계

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 기록된 랩이 일정량 이상인 대상을 고르는 학습용 조건입니다. 40은 공식 F1 기준이나 통계적으로 검증된 기준이 아닙니다. COUNT(lap_duration)은 NULL이 아닌 기록 수이며 공식 완주 랩 수와 항상 같다고 단정하지 않습니다. 평균·조건부 건수·비율에는 타이어, 피트스톱, 세이프티카와 주행 상황이 섞이므로 경기 최종 순위나 실력 순위로 해석하지 않습니다. 109초는 조건부 집계 연습을 위한 시간 기준이며 공식 성능 기준은 아닙니다.

### 테이블 설명

<b>laps — 한 행은 특정 세션에서 드라이버 한 명의 한 랩입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| lap_number | INT | 해당 드라이버의 랩 순번 |
| lap_duration | DECIMAL(12,3) | 랩타임(초), 기록이 없으면 NULL |

당시 학습 스냅샷에는 바쿠 세션 하나만 있었습니다. NULL은 0초가 아니라 시간 기록이 없는 상태입니다.

### 문제

laps에서 <b>랩타임이 기록된 랩이 40개 이상인 드라이버</b>의 번호, 기록된 랩 수, 109초 미만 랩 수를 조회하는 SQL문을 작성한다.

### 조건

- NULL 랩타임은 기록된 랩 수에서 제외한다.
- 정확히 109초인 랩은 109초 미만 랩에 포함하지 않는다.
- 109초 미만 랩이 없어도 기록된 전체 랩이 40개 이상이면 포함하며 해당 건수는 0이다.
- under_109_count 내림차순, 같으면 driver_number 오름차순.

<b>결과 한 행:</b> 조건을 만족한 드라이버 한 명의 통계.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| timed_lap_count | NULL이 아닌 랩타임 수 |
| under_109_count | 109초 미만 랩 수 |

### 출력 예시 — 가상

| driver_number | timed_lap_count | under_109_count |
| --- | --- | --- |
| 7 | 50 | 20 |
| 12 | 45 | 20 |
| 3 | 40 | 0 |

7·12번은 조건부 랩 수가 같아 번호순이다. 3번은 조건부 랩이 없어도 전체 기록 수 40개로 포함된다. 실제 정답 결과가 아닌 설명용 예시다.

### 내 첫 시도·최종 쿼리

```sql
SELECT driver_number,
    COUNT(lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN lap_duration < 109 THEN 1 END) AS under_109_count
FROM laps
GROUP BY driver_number
HAVING timed_lap_count >= 40
ORDER BY under_109_count DESC, driver_number ASC;
```

### 실행 결과·오류

첫 제출에서 조건·집계·정렬이 모두 맞았다. 수정 없음.

### 검증 — 사용자 실제 출력

| driver_number | timed_lap_count | under_109_count |
| --- | --- | --- |
| 63 | 51 | 41 |
| 3 | 51 | 39 |
| 6 | 51 | 39 |
| 16 | 51 | 38 |
| 81 | 51 | 37 |
| 44 | 51 | 35 |
| 12 | 51 | 32 |
| 30 | 51 | 22 |
| 87 | 51 | 22 |
| 31 | 51 | 21 |
| 55 | 51 | 19 |
| 5 | 51 | 14 |
| 41 | 51 | 14 |
| 27 | 51 | 12 |
| 11 | 51 | 11 |
| 77 | 49 | 1 |

16 rows in set (0.07 sec).

### 핵심 개념 정리

전체 기록된 랩과 그중 109초 미만인 랩은 별도 집계한다. CASE 불일치가 NULL이면 COUNT에서 제외된다.

---

## 문제 2. 드라이버별 109초 미만 랩 비율

### 선정 기준의 이유와 해석 한계

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 기록된 랩이 일정량 이상인 대상을 고르는 학습용 조건입니다. 40은 공식 F1 기준이나 통계적으로 검증된 기준이 아닙니다. COUNT(lap_duration)은 NULL이 아닌 기록 수이며 공식 완주 랩 수와 항상 같다고 단정하지 않습니다. 평균·조건부 건수·비율에는 타이어, 피트스톱, 세이프티카와 주행 상황이 섞이므로 경기 최종 순위나 실력 순위로 해석하지 않습니다. 109초 미만 비율은 선정된 각 드라이버의 기록된 전체 랩 수를 분모로 계산합니다.

### 테이블 설명

<b>laps — 한 행은 특정 세션에서 드라이버 한 명의 한 랩입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| lap_number | INT | 해당 드라이버의 랩 순번 |
| lap_duration | DECIMAL(12,3) | 랩타임(초), 기록이 없으면 NULL |

당시 학습 스냅샷에는 바쿠 세션 하나만 있었습니다. NULL은 0초가 아니라 시간 기록이 없는 상태입니다.

### 문제

기록된 랩이 40개 이상인 드라이버의 번호, 기록된 랩 수, 109초 미만 랩 수와 비율을 조회한다.

### 조건

- 비율(%) = 109초 미만 랩 수 / 기록된 전체 랩 수 × 100.
- NULL 랩은 분자·분모 모두에서 제외한다. 정확히 109초인 랩은 분모에는 포함하고 분자에서는 제외한다.
- 비율은 소수점 둘째 자리까지 반올림한다.
- 조건부 랩이 없어도 전체 기록 수 조건을 만족하면 포함하고 건수·비율은 0이다.
- 반올림한 비율 내림차순, 같으면 번호 오름차순.

<b>결과 한 행:</b> 드라이버 한 명의 기록 수와 비율.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| timed_lap_count | 기록된 랩 수 |
| under_109_count | 109초 미만 랩 수 |
| under_109_rate | 109초 미만 랩 비율(%) |

### 출력 예시 — 가상

| driver_number | timed_lap_count | under_109_count | under_109_rate |
| --- | --- | --- | --- |
| 12 | 40 | 20 | 50.00 |
| 7 | 50 | 20 | 40.00 |

같은 20개여도 분모가 달라 비율이 다르다. 실제 정답 결과가 아닌 설명용 예시다.

### 최종 제출·정답 쿼리

```sql
SELECT driver_number,
    COUNT(lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN lap_duration < 109 THEN 1 END) AS under_109_count,
    ROUND(
        COUNT(CASE WHEN lap_duration < 109 THEN 1 END)
        / COUNT(lap_duration) * 100, 2
    ) AS under_109_rate
FROM laps
GROUP BY driver_number
HAVING timed_lap_count >= 40
ORDER BY under_109_rate DESC, driver_number ASC;
```

### 실행 결과·오류

최종 쿼리는 문제의 집계·정렬 조건을 충족합니다.

### 검증 — 사용자 실제 출력

| driver_number | timed_lap_count | under_109_count | under_109_rate |
| --- | --- | --- | --- |
| 63 | 51 | 41 | 80.39 |
| 3 | 51 | 39 | 76.47 |
| 6 | 51 | 39 | 76.47 |
| 16 | 51 | 38 | 74.51 |
| 81 | 51 | 37 | 72.55 |
| 44 | 51 | 35 | 68.63 |
| 12 | 51 | 32 | 62.75 |
| 30 | 51 | 22 | 43.14 |
| 87 | 51 | 22 | 43.14 |
| 31 | 51 | 21 | 41.18 |
| 55 | 51 | 19 | 37.25 |
| 5 | 51 | 14 | 27.45 |
| 41 | 51 | 14 | 27.45 |
| 27 | 51 | 12 | 23.53 |
| 11 | 51 | 11 | 21.57 |
| 77 | 49 | 1 | 2.04 |

16 rows in set (0.06 sec).

63번: 41 / 51 × 100 = 80.39%. 비율 내림차순과 동률 번호순 확인.

<b>해결 상태:</b> 최종 제출 기준 정답, 사용자 실행 확인.

### 핵심 개념 정리

조건부 건수가 같아도 기록된 전체 랩 수가 다르면 비율이 달라질 수 있다.

---

## 문제 3. 팀별 랩타임 통계

### 선정 기준의 이유와 해석 한계

팀 전체 기록 90개 이상은 팀 집계 연습을 위한 선정 조건입니다. 개별 드라이버마다 40개 또는 45개 이상을 요구하는 조건이 아닙니다. 기록 수가 적은 팀을 제외하지만, 90은 공식 F1 기준이나 통계적으로 검증된 기준이 아닙니다. 평균·최고속 랩에는 서로 다른 타이어와 주행 상황이 반영되므로 공식 팀 성적이나 실력 순위로 해석하지 않습니다.

### 테이블 설명

<b>laps — 한 행은 특정 세션에서 드라이버 한 명의 한 랩입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| lap_number | INT | 해당 드라이버의 랩 순번 |
| lap_duration | DECIMAL(12,3) | 랩타임(초), 기록이 없으면 NULL |

당시 학습 스냅샷에는 바쿠 세션 하나만 있었습니다. NULL은 0초가 아니라 시간 기록이 없는 상태입니다.

<b>drivers — 한 행은 세션에 참가한 드라이버 한 명입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| full_name | VARCHAR(100) | 드라이버 이름 |
| team_name | VARCHAR(100) | 팀 이름 |

같은 session_key와 driver_number를 가진 행끼리 같은 세션의 같은 드라이버입니다.

### 문제

두 테이블을 이용해 <b>팀 전체의 기록된 랩이 90개 이상인 팀</b>의 이름, 기록된 랩 수, 평균과 가장 짧은 랩타임을 조회한다.

### 조건

- 소속 드라이버들의 랩을 합쳐 계산하며 개인 최소 랩 조건은 없다.
- NULL은 랩 수·평균·최솟값 계산에서 제외한다.
- 기록이 정확히 90개인 팀도 포함한다.
- 평균·최솟값은 소수점 둘째 자리까지 반올림한다.
- 반올림한 평균 오름차순, 같으면 팀 이름 오름차순.
- lap_details는 사용하지 않는다.

<b>결과 한 행:</b> 팀 하나의 통계.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 팀 이름 |
| timed_lap_count | 팀의 기록된 랩 수 |
| avg_lap_duration | 팀 랩타임 평균(초) |
| fastest_lap_duration | 팀에서 가장 짧은 랩타임(초) |

### 출력 예시 — 가상

| team_name | timed_lap_count | avg_lap_duration | fastest_lap_duration |
| --- | --- | --- | --- |
| Team A | 100 | 115.20 | 105.30 |
| Team B | 90 | 116.40 | 106.10 |

A의 두 드라이버가 각각 50개 기록했다면 총 100개다. B는 정확히 90개라 포함한다. 실제 결과가 아닌 설명용 예시다.

### 내 첫 시도

```sql
SELECT d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration,
    ROUND(MIN(l.lap_duration), 2) AS fastest_lap_duration
FROM drivers d
JOIN laps l ON l.session_key = d.session_key AND l.driver_number = d.driver_number
GROPU BY d.team_name
HAVING timed_lap_count >= 90
ORDER BY avg_lap_durationn ASC, team_name ASC;
```

### 실행 결과·오류

GROPU BY, avg_lap_durationn 두 오타가 있었다. 수정 후 JOIN 줄 끝의 특수 공백이 컬럼명 일부로 인식된 것으로 보이는 오류가 발생했다.

```txt
ERROR 1054 (42S22): Unknown column 'd.driver_number ' in 'on clause'
```

### 틀린 이유·수정 사항

복합 JOIN·팀별 그룹화·COUNT·AVG·MIN·HAVING·정렬 논리는 맞습니다.

### 최종 쿼리

```sql
SELECT d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration,
    ROUND(MIN(l.lap_duration), 2) AS fastest_lap_duration
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY d.team_name
HAVING timed_lap_count >= 90
ORDER BY avg_lap_duration ASC, d.team_name ASC;
```

### 검증 — 사용자 실제 출력

| team_name | timed_lap_count | avg_lap_duration | fastest_lap_duration |
| --- | --- | --- | --- |
| Red Bull Racing | 102 | 115.45 | 104.99 |
| Mercedes | 102 | 115.49 | 104.92 |
| Ferrari | 102 | 115.70 | 105.78 |
| Haas F1 Team | 102 | 115.96 | 106.98 |
| Racing Bulls | 102 | 115.98 | 106.85 |
| Audi | 102 | 116.01 | 106.34 |
| Cadillac | 100 | 116.54 | 107.36 |

7 rows in set (0.08 sec).

### 핵심 개념 정리

팀 전체 랩을 묶고 평균과 MIN을 계산한다. 가장 짧은 랩 한 번과 전체 평균은 다른 지표다.
</details>

<details>
<summary>🧩 문제 4 — 서브쿼리로 조건에 맞는 드라이버 수</summary>

## 문제 4. 110초 미만 랩이 35개 이상인 드라이버 수

### 선정 기준의 이유와 해석 한계

이 문제는 전체 기록 수가 아니라 110초 미만으로 기록된 랩 자체가 35개 이상인 드라이버를 세는 조건입니다. 35개와 110초는 조건부 집계·서브쿼리 연습용 임계값이며 공식 F1 기준은 아닙니다. 기록 수가 많은 드라이버는 조건을 충족할 기회도 많으므로 실제 경기 최종 순위나 실력 순위와 구분합니다.

### 테이블 설명

<b>laps — 한 행은 특정 세션에서 드라이버 한 명의 한 랩입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| lap_number | INT | 해당 드라이버의 랩 순번 |
| lap_duration | DECIMAL(12,3) | 랩타임(초), 기록이 없으면 NULL |

당시 학습 스냅샷에는 바쿠 세션 하나만 있었습니다. NULL은 0초가 아니라 시간 기록이 없는 상태입니다.

### 문제

<b>110초 미만인 랩이 35개 이상인 드라이버가 몇 명인지</b> 조회한다.

### 조건

- 드라이버별로 110초 미만 랩 수를 판단한다. 전체 기록 수가 35개 이상이라는 뜻이 아니다.
- 정확히 110초와 NULL은 조건부 랩 수에서 제외한다.
- 35개도 포함한다. 사람 목록이나 랩 수 합계 대신 드라이버 수 한 행을 출력한다.
- 조건을 만족하는 드라이버가 없으면 0. 정렬 없음.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| driver_count | 조건을 만족하는 드라이버 수 |

### 예시 — 가상 집계와 최종 출력

| driver_number | 110초 미만 랩 수 |
| --- | --- |
| 7 | 42 |
| 12 | 35 |
| 3 | 34 |

이 표는 원본이 아닌 설명용 요약이다. 7·12번만 조건을 만족하므로 최종 예시는 다음과 같다.

| driver_count |
| --- |
| 2 |

42+35인 77을 출력하는 문제가 아니라 두 드라이버를 세는 문제다.

### 내 첫 시도

```sql
SELECT COUNT(driver) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS timed_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 35
) AS driver;
```

### 실행 결과·오류

첫 시도의 실제 오류 메시지는 제출되지 않았다. 코드 검토에서 바깥 COUNT의 driver가 컬럼이 아닌 표 별칭임을 확인했다. 안쪽 집계·GROUP BY·HAVING과 전체 서브쿼리 틀은 직접 정확히 작성했다.

### 틀린 이유·수정 사항

COUNT(driver)는 driver라는 컬럼을 찾는다. 중간 표의 행 수를 세려면 COUNT(\*)를 사용한다. 표 별칭과 컬럼 별칭을 구분한다.

### 최종 쿼리

```sql
SELECT COUNT(*) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS timed_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 35
) AS driver;
```

### 검증 — 사용자 실제 출력

| driver_count |
| --- |
| 11 |

1 row in set (0.00 sec).

### 내 말로 정리·이해 점검

묶는 역할은 안쪽 GROUP BY다. 바깥 COUNT는 남은 행을 센다. 안쪽 한 행이 드라이버 한 명이므로 11행은 11명이다.

COUNT 안에서 모든 별칭이 금지되는 것은 아니다. driver는 표 별칭이라 COUNT(driver)는 불가하지만, 바깥에서 COUNT(driver.driver_number)나 COUNT(driver.timed_lap_duration)처럼 중간 결과의 컬럼은 사용할 수 있다. 각각 NULL이 아닌 값을 세며, 이번 driver_number는 NULL이 아니므로 COUNT(\*)와 같다.

timed_lap_duration은 사용자 별칭을 보존했다. 실제 단위는 시간 길이가 아닌 조건부 랩 건수이므로 under_110_count가 더 명확한 이름이다.
</details>

<details>
<summary>🧩 문제 5 — 드라이버별 평균 랩타임의 평균</summary>

## 문제 5. 드라이버별 평균 랩타임의 평균

### 선정 기준의 이유와 해석 한계

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 기록된 랩이 일정량 이상인 대상을 고르는 학습용 조건입니다. 40은 공식 F1 기준이나 통계적으로 검증된 기준이 아닙니다. COUNT(lap_duration)은 NULL이 아닌 기록 수이며 공식 완주 랩 수와 항상 같다고 단정하지 않습니다. 평균·조건부 건수·비율에는 타이어, 피트스톱, 세이프티카와 주행 상황이 섞이므로 경기 최종 순위나 실력 순위로 해석하지 않습니다. 대상 드라이버별 평균을 다시 평균 낼 때는 드라이버 한 명당 같은 비중을 줍니다. 전체 랩을 한꺼번에 평균 내는 값과는 가중치가 다릅니다.

### 테이블 설명

<b>laps — 한 행은 특정 세션에서 드라이버 한 명의 한 랩입니다.</b>

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| session_key | INT | 세션 ID |
| driver_number | INT | 드라이버 번호 |
| lap_number | INT | 해당 드라이버의 랩 순번 |
| lap_duration | DECIMAL(12,3) | 랩타임(초), 기록이 없으면 NULL |

당시 학습 스냅샷에는 바쿠 세션 하나만 있었습니다. NULL은 0초가 아니라 시간 기록이 없는 상태입니다.

### 문제

<b>랩타임이 기록된 랩이 40개 이상인 드라이버 각각의 평균 랩타임</b>을 구하고, <b>그 드라이버별 평균값들의 평균</b>을 조회한다.

드라이버마다 기록된 랩 수가 달라도 최종 평균에는 드라이버 한 명당 같은 비중으로 반영한다.

### 조건

- NULL은 기록 수와 평균 계산에서 제외한다.
- 기록 수가 정확히 40개인 드라이버도 포함한다.
- 드라이버별 평균은 중간에 반올림하지 않는다.
- 최종 평균만 소수점 둘째 자리까지 반올림한다.
- 최종 결과는 한 행이며 정렬은 없다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| avg_driver_lap_duration | 대상 드라이버별 평균 랩타임의 평균(초) |

### 출력 예시 — 가상

조건을 만족한 두 드라이버의 평균이 110초·114초이면 (110+114)/2 = 112초다. 두 드라이버의 랩 수가 달라도 평균값 하나씩 동일한 비중으로 계산한다.

| avg_driver_lap_duration |
| --- |
| 112.00 |

이 표는 최종 출력 형태다. 중간 결과가 한 행이어야 한다는 뜻이 아니며, 정식 문제에는 중간 SQL 틀을 제공하지 않는다.

### 내 첫 시도

```sql
SELECT ROUND(AVG(avg_lap_duration), 2) AS avg_driver_lap_duration
FROM (
    SELECT COUNT(lap_duration) AS timed_lap_duration,
        ROUND(AVG(lap_duration), 2) AS avg_lap_duration
    FROM laps
    HAVING timed_lap_duration >= 40
) AS driver;
```

### 실행 결과·오류

첫 실행 결과 115.78, 1 row in set (0.00 sec). GROUP BY가 없어 전체 랩 평균 한 행을 다시 평균 낸 결과였다.

GROUP BY를 추가한 다음 시도에서는 안쪽 ROUND(AVG(lap_duration))가 남아 정수 반올림된 값들을 평균 냈다. 결과 115.94, 1 row in set (0.08 sec).

ROUND를 제거하는 과정에서 닫는 괄호 하나가 남아 다음 오류가 발생했다.

```txt
ERROR 1064 (42000): You have an error in your SQL syntax
```

오류가 있던 표현:

```sql
AVG(lap_duration) ) AS avg_lap_duration
```

### 틀린 이유·수정 사항

- 바깥 AVG를 쓰는 방향은 처음부터 맞았다. 안쪽에서 driver_number별 GROUP BY로 드라이버 한 명당 평균값 하나를 만들어야 한다.
- ROUND(값)에 자릿수를 생략해도 반올림이 없어지는 것이 아니라 정수 반올림이 된다.
- 중간에 반올림하면 계산에 사용할 평균값이 바뀐다. 이번 조건은 원래 평균을 유지하고 최종만 반올림하도록 요구한다.
- AVG 뒤 불필요한 괄호를 제거했다.

### 최종 쿼리

```sql
SELECT ROUND(AVG(avg_lap_duration), 2) AS avg_driver_lap_duration
FROM (
    SELECT COUNT(lap_duration) AS timed_lap_duration,
        AVG(lap_duration) AS avg_lap_duration
    FROM laps
    GROUP BY driver_number
    HAVING timed_lap_duration >= 40
) AS driver;
```

### 검증 — 사용자 실제 출력

| avg_driver_lap_duration |
| --- |
| 115.90 |

1 row in set (0.07 sec).

### 핵심 개념 정리·이해 점검

최종 결과가 한 행이어도 중간 집계는 드라이버별 여러 행입니다. 드라이버별 평균을 다시 평균 낼 때 각 드라이버에 같은 비중을 줍니다.

안쪽은 드라이버마다 평균 한 개를 만들고, 바깥은 그 값들의 평균 하나를 만든다. 최종 한 행을 만들기 위해 중간까지 한 행이어야 하는 것은 아니다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — COUNT·별칭·집계 단위·반올림</summary>

## 오늘 구분해야 할 단위

| 상황 | 세거나 평균 내는 대상 |
| --- | --- |
| P1·P2 | 드라이버별 랩 |
| P3 | 팀 소속 드라이버들의 랩 전체 |
| P4 안쪽 | 드라이버별 조건부 랩 수 |
| P4 바깥 | 선별된 드라이버 행 |
| P5 안쪽 | 드라이버 한 명의 랩타임 |
| P5 바깥 | 드라이버별 평균값 |

## COUNT와 별칭

COUNT(\*)는 행을 세고 GROUP BY는 그룹을 만든다. 표 별칭은 컬럼이 아니다. 안쪽 SELECT의 컬럼 별칭은 중간 결과의 컬럼이므로 바깥 쿼리에서 참조할 수 있다.

## 최종 출력과 중간 집계

최종 한 행이라는 요구는 결과의 모양이다. 필요한 중간 집계는 “드라이버별 평균값들의 평균”, “조건에 맞는 드라이버 수” 같은 문장에서 판단한다. 문제에는 집계 대상·비중·NULL·반올림을 명확히 적고 풀이 SQL은 미리 제공하지 않는다.

## 반올림을 언제 하는가?

설명용 가상 평균이 110.49와 110.48일 때 중간 정수 반올림 후 평균은 110.00이다. 원래 값의 평균 110.485를 최종 2자리로 반올림하면 110.49다. 이번처럼 최종 정밀도를 유지해야 할 때는 중간 반올림을 하지 않는다.

## 오류 구분

문법 오류와 집계 논리 오류는 원인과 해결 방법이 다릅니다.
</details>

<details>
<summary>🧠 오늘의 회고·검증 범위·재풀이</summary>

## 오늘 결과

| 문제 | 판정·실행 결과 |
| --- | --- |
| P1 | 정답·16행 |
| P2 | 최종 제출 정답·16행 |
| P3 | 풀이 논리 정답·7행 |
| P4 | 정답·11명 |
| P5 | 정답·115.90초 |

5문제의 MySQL 실행 결과를 확인했습니다.

## 관찰된 진전

P1에서 바뀐 임계값에 조건부 COUNT를 직접 적용했고 P2에서 비율의 분자·분모를 맞췄다. P3는 복합 JOIN과 팀별 COUNT·AVG·MIN을 직접 선택했다. P4는 전날보다 서브쿼리 틀·안쪽 집계·HAVING을 직접 구성했고 바깥 COUNT 대상만 수정했다.

## 계속 연습할 부분

표 별칭과 컬럼의 차이, GROUP BY와 COUNT의 역할, 최종 한 행과 중간 여러 행, 그룹별 평균에 같은 비중을 주는 의미, 중간 반올림 없이 정밀도를 유지하는 이유.

## 복습

- [ ] P4를 답 없이 다시 작성하고 안쪽 결과 한 행의 의미 설명
- [ ] P5를 답 없이 다시 작성하고 두 AVG의 대상 설명
- [ ] P5에서 GROUP BY를 빼면 어떤 평균으로 바뀌는지 설명

<b>재풀이 상태: 미실행.</b>

## 수업 운영 수정

SQL 튜터 스킬과 에이전트 지침에 접속 안내, 분야별 2일 학습, 상세 문제 형식, 단계별 피드백, Notion 최근 양식 확인 규칙을 반영했다. 여러 단계 집계 문제는 계산 대상을 문장에 명시하고, 최종 한 행 예시와 풀이용 중간 표를 구분하도록 보완했다.
</details>
</details>
