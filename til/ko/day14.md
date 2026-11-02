# 🏎️ Day14 — Baku F1 집계·JOIN·조건부 COUNT·서브쿼리

[English](../en/day14.md) · [목차](../../README.ko.md) · [검증 기록](../../docs/audit.ko.md)

<details>
<summary>🏎️ Day14 — Baku F1 집계·JOIN·조건부 COUNT·서브쿼리</summary>

<b>재실행 범위:</b> 아래 SQL·결과는 바쿠 단일 세션 11377 기준의 과거 학습 기록입니다. 현재 f1_study에는 19경기가 있어 필터 없이 실행하면 다른 결과가 나옵니다. 이번 재검증은 원본 쿼리를 바꾸지 않고 세션 11377만 노출하는 별도 조회 환경에서 수행했습니다. 직접 재실행할 때는 모든 원본 테이블의 세션을 바쿠로 제한해야 합니다.

# SQL 학습 기록 — Day 14

## 학습 개요

<b>환경:</b> MySQL / f1_study / laps·drivers·lap_details

<b>범위:</b> NULL 집계·복합 JOIN·조건부 COUNT·팀별 비율·서브쿼리, P1\~P5.

<b>검증 근거:</b> 사용자 직접 MySQL 실행 결과.

### 접속

터미널:

```bash
mysql -u root -p
```

MySQL:

```sql
USE f1_study;
SHOW TABLES;
```

터미널 % 화면에서 USE·SHOW를 입력해 zsh: command not found 오류가 났다. MySQL 접속 후 mysql> 화면에서 실행하여 해결했다.

### 데이터와 한 행의 의미

<b>무엇을 분석하나요?</b> 바쿠 F1 프로젝트에 저장된 레이스 세션의 랩 기록으로, 드라이버별·팀별 기록 수와 랩타임을 집계합니다.

<b>용어:</b> 랩(lap)은 서킷 한 바퀴입니다. 세션(session)은 기록이 수집된 경기·주행 단위입니다. 랩타임은 한 바퀴에 걸린 시간이며 초 단위입니다.

| 테이블·뷰 | 한 행의 의미 | 행 수 | 오늘 사용 |
| --- | --- | --- | --- |
| drivers | 세션에 참가한 드라이버 한 명 | 22 | P2·P3·P4 |
| laps | 특정 세션에서 드라이버 한 명의 한 랩 | 983 | P2·P3·P4·P5 |
| lap_details | laps에 드라이버 이름·팀을 붙인 조회용 뷰 | 983 | P1 |
| stints | 드라이버의 타이어 사용 구간 하나 | 58 | 오늘 사용하지 않음 |

### 원본 테이블의 주요 컬럼

아래는 전체 컬럼 중 오늘 문제에 필요한 컬럼입니다. 자료형·NULL 허용 여부는 실제 MySQL 테이블에서 확인했습니다.

<b>`laps`</b>

한 행의 의미: 특정 세션에서 드라이버 한 명이 주행한 한 랩.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| lap_number | INT | 불가 | 해당 드라이버의 랩 순번. 1은 첫 번째 랩 |
| lap_duration | DECIMAL(12,3) | 허용 | 한 랩을 도는 데 걸린 시간(초). 109.236은 109.236초 |

<b>laps의 기본키:</b> session_key + driver_number + lap_number. 세 값을 합쳐 랩 한 행을 구분합니다. 서로 다른 드라이버에게 lap_number = 1이 있어도 중복 오류가 아닙니다.

<b>`drivers`</b>

한 행의 의미: 세션에 참가한 드라이버 한 명.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| full_name | VARCHAR(100) | 허용 | 드라이버 이름 |
| team_name | VARCHAR(100) | 허용 | 드라이버의 소속 팀 이름 |

<b>drivers의 기본키:</b> session_key + driver_number. 같은 세션·같은 드라이버에 해당하는 정보는 한 행입니다.

<b>테이블 연결:</b> laps의 각 랩은 같은 session_key와 driver_number를 가진 drivers 행에 연결됩니다. 한 드라이버 정보에 여러 랩이 연결되는 관계입니다.

<b>lap_details는 무엇인가요?</b> laps에 drivers의 이름·팀을 붙여 보여 주는 뷰(저장된 조회식)입니다. 랩을 추가로 복사한 테이블이 아닙니다. 오늘 P1에서는 이 뷰를 사용하고, P2\~P4에서는 직접 두 테이블을 연결합니다.

### 실제 원본 데이터 예시

다음 3행은 이번 설명 보완 시 MySQL에서 직접 확인한 laps 일부입니다. 가상 데이터가 아닙니다.

| session_key | driver_number | lap_number | lap_duration |
| --- | --- | --- | --- |
| 11377 | 3 | 1 | 116.589 |
| 11377 | 3 | 2 | 109.236 |
| 11377 | 3 | 3 | 109.023 |

같은 드라이버 3번의 1·2·3번째 랩입니다. 116.589는 116.589초이며, 이 3행만 보면 110초 미만은 두 랩입니다. 드라이버의 전체 기록을 보여 준 표는 아닙니다.

### NULL과 집계 기준

- 전체 랩 983개 중 lap_duration이 기록된 랩은 976개이고, NULL인 랩은 7개입니다.
- NULL은 랩타임을 확인할 수 없다는 뜻이며 0초나 110초 이상이라는 뜻이 아닙니다.
- 기록된 랩 수는 NULL이 아닌 랩타임의 수입니다. 전체 랩 행 수와 구분합니다.
- 당시 학습 스냅샷에는 바쿠 세션 하나만 있었지만, 테이블 연결 시 세션 ID와 드라이버 번호를 모두 확인합니다.
- 110초 기준은 이번 SQL 연습의 분류 기준이며 공식적인 성능 평가 기준이 아닙니다.

출처: [바쿠 프로젝트의 고정 데이터 스냅샷](https://github.com/madferit94/all-sports-analytics/tree/c1e22c8f1d0f14192f92159d59b7b8f12a307ef5/f1/baku-2026). 적재 검증은 원본 CSV와 DB의 일치를 확인한 것이며 원 제공 데이터의 사실성 전체를 재검증한 것은 아닙니다.

<details>
<summary>📚 문제 1\~4 — 드라이버·팀 집계와 JOIN·비율</summary>

## 문제 1. 드라이버별 평균 랩타임

### 선정 기준의 이유와 해석 한계

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 기록된 랩이 일정량 이상인 대상을 고르는 학습용 조건입니다. 40은 공식 F1 기준이나 통계적으로 검증된 기준이 아닙니다. COUNT(lap_duration)은 NULL이 아닌 기록 수이며 공식 완주 랩 수와 항상 같다고 단정하지 않습니다. 평균·조건부 건수·비율에는 타이어, 피트스톱, 세이프티카와 주행 상황이 섞이므로 경기 최종 순위나 실력 순위로 해석하지 않습니다.

### 테이블 설명

<b>`lap_details`</b>

한 행의 의미: 특정 세션에서 드라이버 한 명이 주행한 한 랩에 이름·팀을 붙인 기록.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| full_name | VARCHAR(100) | 허용 | 드라이버 이름 |
| lap_number | INT | 불가 | 해당 드라이버의 랩 순번. 1은 첫 번째 랩 |
| lap_duration | DECIMAL(12,3) | 허용 | 한 랩을 도는 데 걸린 시간(초). 109.236은 109.236초 |

이번 문제는 이미 이름이 연결된 lap_details를 사용합니다. 직접 테이블을 연결할 필요는 없습니다.

### 문제

lap_details에서 <b>랩타임이 기록된 랩이 40개 이상인 드라이버</b>의 번호, 이름, 기록된 랩 수, 평균 랩타임을 조회하는 SQL문을 작성해 주세요.

### 조건

- lap_duration이 NULL인 랩은 랩 수와 평균 계산에서 제외합니다.
- 기록된 랩이 정확히 40개인 드라이버도 포함합니다.
- 평균 랩타임은 초 단위로 계산하고 소수점 둘째 자리까지 반올림합니다.
- 결과는 반올림한 평균 랩타임 오름차순으로 정렬합니다.
- 평균이 같다면 드라이버 번호 오름차순으로 정렬합니다.

<b>결과 한 행의 의미:</b> 조건을 만족한 드라이버 한 명의 주행 통계.

### 출력 컬럼

| 컬럼명 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 드라이버 이름 |
| timed_lap_count | 랩타임이 기록된 랩 수. NULL인 랩은 제외 |
| avg_lap_duration | 기록된 랩타임의 평균(초), 소수점 둘째 자리까지 반올림 |

### 출력 예시 — 가상 데이터

아래는 문제 형식을 설명하기 위한 가상 결과이며 실제 바쿠 실행 결과가 아닙니다. 실제 결과는 아래 검증 항목에 별도로 기록합니다.

| driver_number | full_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- |
| 7 | Driver A | 45 | 110.25 |
| 12 | Driver B | 48 | 110.25 |
| 3 | Driver C | 40 | 112.80 |

### 예시 설명

세 드라이버 모두 기록된 랩이 40개 이상입니다. A와 B는 평균이 같아 번호 7인 A가 먼저 나옵니다. 기록된 랩이 39개인 드라이버는 출력하지 않습니다.

### 내 첫 시도

```sql
SELECT driver_number, full_name, lap_number,
    ROUND(AVG(lap_duration), 2) AS avg_lap_duration
FROM lap_details
GROUP BY driver_number
HAVING avg_lap_duration >= 40
ORDER BY avg_lap_duration ASC, driver_number DESC;
```

### 실행 결과·오류

첫 시도의 실제 실행 결과나 오류 메시지는 공유되지 않았다. 코드 검토에서 집계 기준과 정렬 오류를 발견했다. 수정 과정에서 lap_duraton, timed_lap_countå 오타가 있었고 lap_number도 남아 있었다.

### 틀린 이유

40은 평균 초수가 아니라 기록된 랩 수 조건이다. 개별 lap_number는 드라이버별 통계의 출력 대상이 아니다. 이름을 포함한 그룹 기준과 번호 ASC도 수정했다.

### 수정 쿼리

```sql
SELECT driver_number, full_name,
    COUNT(lap_duration) AS timed_lap_count,
    ROUND(AVG(lap_duration), 2) AS avg_lap_duration
FROM lap_details
GROUP BY driver_number, full_name
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;
```

### 검증

실행 결과: 16 rows in set (0.02 sec).

| driver_number | full_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- |
| 63 | George RUSSELL | 51 | 115.34 |
| 3 | Max VERSTAPPEN | 51 | 115.35 |
| 6 | Isack HADJAR | 51 | 115.55 |
| 16 | Charles LECLERC | 51 | 115.62 |
| 12 | Kimi ANTONELLI | 51 | 115.63 |
| 44 | Lewis HAMILTON | 51 | 115.78 |
| 31 | Esteban OCON | 51 | 115.95 |
| 41 | Arvid LINDBLAD | 51 | 115.95 |
| 87 | Oliver BEARMAN | 51 | 115.97 |
| 55 | Carlos SAINZ | 51 | 115.98 |
| 27 | Nico HULKENBERG | 51 | 116.00 |
| 5 | Gabriel BORTOLETO | 51 | 116.01 |
| 30 | Liam LAWSON | 51 | 116.01 |
| 81 | Oscar PIASTRI | 51 | 116.06 |
| 11 | Sergio PEREZ | 51 | 116.16 |
| 77 | Valtteri BOTTAS | 49 | 116.94 |

COUNT(lap_duration)와 AVG(lap_duration)은 모두 NULL을 제외한다. 문제의 요구는 기록된 랩 집계이므로 WHERE 없이 같은 결과를 구했다.

### 핵심 개념 정리

전체 행 수와 랩타임이 기록된 행 수는 다르다. 40개 조건은 COUNT 결과에 적용한다.

---

## 문제 2. JOIN으로 드라이버·팀 정보 연결

### 선정 기준의 이유와 해석 한계

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 기록된 랩이 일정량 이상인 대상을 고르는 학습용 조건입니다. 40은 공식 F1 기준이나 통계적으로 검증된 기준이 아닙니다. COUNT(lap_duration)은 NULL이 아닌 기록 수이며 공식 완주 랩 수와 항상 같다고 단정하지 않습니다. 평균·조건부 건수·비율에는 타이어, 피트스톱, 세이프티카와 주행 상황이 섞이므로 경기 최종 순위나 실력 순위로 해석하지 않습니다.

### 테이블 설명

<b>`laps`</b>

한 행의 의미: 특정 세션에서 드라이버 한 명이 주행한 한 랩.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| lap_number | INT | 불가 | 해당 드라이버의 랩 순번. 1은 첫 번째 랩 |
| lap_duration | DECIMAL(12,3) | 허용 | 한 랩을 도는 데 걸린 시간(초). 109.236은 109.236초 |

<b>`drivers`</b>

한 행의 의미: 세션에 참가한 드라이버 한 명.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| full_name | VARCHAR(100) | 허용 | 드라이버 이름 |
| team_name | VARCHAR(100) | 허용 | 드라이버의 소속 팀 이름 |

<b>두 테이블의 관계:</b> session_key와 driver_number가 모두 같은 행은 같은 세션의 같은 드라이버를 나타냅니다. 드라이버 한 명의 정보에 여러 랩 기록이 연결될 수 있습니다.

### 문제

laps와 drivers를 이용하여 <b>랩타임이 기록된 랩이 40개 이상인 드라이버</b>의 번호, 이름, 소속 팀, 기록된 랩 수, 평균 랩타임을 조회하는 SQL문을 작성해 주세요.

### 조건

- lap_details는 사용하지 않고 laps와 drivers를 연결합니다.
- lap_duration이 NULL인 랩은 랩 수와 평균 계산에서 제외합니다.
- 드라이버별 기록된 랩 수가 40개 이상이어야 합니다.
- 평균은 소수점 둘째 자리까지 반올림합니다.
- 반올림한 평균 랩타임 오름차순, 같으면 드라이버 번호 오름차순으로 정렬합니다.

<b>결과 한 행의 의미:</b> 조건을 만족한 드라이버 한 명의 이름·팀·주행 통계.

### 출력 컬럼

| 컬럼명 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 드라이버 이름 |
| team_name | 소속 팀 |
| timed_lap_count | 랩타임이 기록된 랩 수. NULL인 랩은 제외 |
| avg_lap_duration | 기록된 랩타임의 평균(초), 소수점 둘째 자리까지 반올림 |

### 출력 예시 — 가상 데이터

아래는 실제 바쿠 실행 결과가 아닌 가상 결과입니다.

| driver_number | full_name | team_name | timed_lap_count | avg_lap_duration |
| --- | --- | --- | --- | --- |
| 7 | Driver A | Team X | 45 | 110.25 |
| 12 | Driver B | Team Y | 48 | 110.25 |
| 3 | Driver C | Team X | 40 | 112.80 |

### 예시 설명

문제 1의 드라이버별 통계에 팀 정보를 함께 표시합니다. A와 C의 팀이 같더라도 이 문제는 드라이버별 통계이므로 서로 다른 행으로 출력합니다.

### 내 첫 시도

```sql
SELECT l.driver_number, d.full_name, d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration
FROM drivers d
JOIN laps l ON l.session_key = d.session_key
GROUP BY d.driver_number
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;
```

### 실행 결과·오류

첫 시도의 출력은 제출되지 않았다. 코드 검토에서 드라이버 번호 JOIN 조건 누락을 확인했다.

### 틀린 이유

같은 세션이라는 조건만으로 연결하면 다른 드라이버의 랩까지 붙는다. 같은 세션과 같은 드라이버를 모두 확인해야 한다. GROUP BY도 출력 단위에 맞게 수정했다.

### 수정 쿼리

```sql
SELECT l.driver_number, d.full_name, d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    ROUND(AVG(l.lap_duration), 2) AS avg_lap_duration
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY avg_lap_duration ASC, driver_number ASC;
```

### 검증

실행 결과: 16 rows in set (0.08 sec).

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

P1과 같은 16명·랩 수·평균에 팀 정보가 추가됐다.

### 내 말로 정리·이해 확인

한 행의 의미와 키를 보고 연결 조건을 정한다. INNER JOIN은 이번처럼 같은 조건이면 laps를 먼저 적어도 같은 결과다. LEFT JOIN은 왼쪽 행을 유지하므로 순서에 의미가 있다.

---

## 문제 3. 드라이버별 110초 미만 랩 수

### 선정 기준의 이유와 해석 한계

기록이 아주 적은 드라이버와 많은 드라이버를 바로 비교하지 않도록, 기록된 랩이 일정량 이상인 대상을 고르는 학습용 조건입니다. 40은 공식 F1 기준이나 통계적으로 검증된 기준이 아닙니다. COUNT(lap_duration)은 NULL이 아닌 기록 수이며 공식 완주 랩 수와 항상 같다고 단정하지 않습니다. 평균·조건부 건수·비율에는 타이어, 피트스톱, 세이프티카와 주행 상황이 섞이므로 경기 최종 순위나 실력 순위로 해석하지 않습니다. 이 문제의 40은 전체 기록 수에 적용하며, 110초 미만 기록이 40개여야 한다는 뜻은 아닙니다.

### 테이블 설명

<b>`laps`</b>

한 행의 의미: 특정 세션에서 드라이버 한 명이 주행한 한 랩.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| lap_number | INT | 불가 | 해당 드라이버의 랩 순번. 1은 첫 번째 랩 |
| lap_duration | DECIMAL(12,3) | 허용 | 한 랩을 도는 데 걸린 시간(초). 109.236은 109.236초 |

<b>`drivers`</b>

한 행의 의미: 세션에 참가한 드라이버 한 명.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| full_name | VARCHAR(100) | 허용 | 드라이버 이름 |
| team_name | VARCHAR(100) | 허용 | 드라이버의 소속 팀 이름 |

<b>두 테이블의 관계:</b> session_key와 driver_number가 모두 같은 행은 같은 세션의 같은 드라이버를 나타냅니다. 드라이버 한 명의 정보에 여러 랩 기록이 연결될 수 있습니다.

### 문제

laps와 drivers를 이용하여 <b>랩타임이 기록된 랩이 40개 이상인 드라이버</b>의 번호, 이름, 기록된 랩 수, <b>110초 미만인 랩 수</b>를 조회하는 SQL문을 작성해 주세요.

### 조건

- lap_details는 사용하지 않습니다.
- timed_lap_count에는 NULL이 아닌 모든 랩타임 기록을 셉니다. 110초 이상인 랩도 포함합니다.
- under_110_count에는 그중 110초 미만인 랩만 셉니다. 정확히 110초인 랩은 포함하지 않습니다.
- 기록된 전체 랩이 40개 이상인 드라이버만 출력합니다. 110초 미만 랩이 40개 이상이어야 한다는 뜻이 아닙니다.
- 110초 미만 랩이 없는 드라이버도 전체 기록된 랩이 40개 이상이면 포함하고, under_110_count를 0으로 표시합니다.
- under_110_count 내림차순, 같으면 드라이버 번호 오름차순으로 정렬합니다.

<b>결과 한 행의 의미:</b> 조건을 만족한 드라이버 한 명의 전체 기록 수와 110초 미만 기록 수.

### 출력 컬럼

| 컬럼명 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 드라이버 이름 |
| timed_lap_count | 랩타임이 기록된 랩 수. NULL인 랩은 제외 |
| under_110_count | 그중 랩타임이 110초 미만인 랩 수 |

### 출력 예시 — 가상 데이터

아래는 실제 바쿠 실행 결과가 아닌 가상 결과입니다.

| driver_number | full_name | timed_lap_count | under_110_count |
| --- | --- | --- | --- |
| 7 | Driver A | 45 | 12 |
| 12 | Driver B | 48 | 12 |
| 3 | Driver C | 40 | 0 |

### 예시 설명

A는 기록된 45개 랩 중 12개가 110초 미만입니다. C는 110초 미만 랩이 없지만 전체 기록된 랩이 40개이므로 포함됩니다. A와 B의 조건부 랩 수가 같아 번호 순으로 정렬합니다.

### 내 첫 시도

```sql
SELECT l.driver_number, d.full_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    COUNT(l.lap_duration > 110) AS under_110_count
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY under_110_count DESC, driver_number ASC;
```

### 실행 결과·오류

문법 오류 없이 16행이 출력됐지만 under_110_count가 timed_lap_count와 모두 같았다. 대부분 51, BOTTAS는 49였다.

### 틀린 이유

미만은 >가 아니라 \<이다. MySQL 비교 결과는 참 1, 거짓 0이며 COUNT는 0도 센다. NULL이 아닌 비교 결과를 모두 세어 전체 기록된 랩 수와 같아졌다.

### 수정 쿼리

```sql
SELECT l.driver_number, d.full_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END) AS under_110_count
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 40
ORDER BY under_110_count DESC, driver_number ASC;
```

### 검증

실행 결과: 16 rows in set (0.01 sec).

| driver_number | full_name | timed_lap_count | under_110_count |
| --- | --- | --- | --- |
| 3 | Max VERSTAPPEN | 51 | 42 |
| 6 | Isack HADJAR | 51 | 42 |
| 63 | George RUSSELL | 51 | 42 |
| 81 | Oscar PIASTRI | 51 | 41 |
| 16 | Charles LECLERC | 51 | 40 |
| 44 | Lewis HAMILTON | 51 | 40 |
| 12 | Kimi ANTONELLI | 51 | 38 |
| 87 | Oliver BEARMAN | 51 | 38 |
| 41 | Arvid LINDBLAD | 51 | 36 |
| 30 | Liam LAWSON | 51 | 35 |
| 31 | Esteban OCON | 51 | 35 |
| 27 | Nico HULKENBERG | 51 | 33 |
| 5 | Gabriel BORTOLETO | 51 | 31 |
| 55 | Carlos SAINZ | 51 | 28 |
| 11 | Sergio PEREZ | 51 | 26 |
| 77 | Valtteri BOTTAS | 49 | 9 |

GROUP BY의 team_name은 이번 데이터에서 불필요하지만 제출본 그대로 보존했다. 제공 결과에는 0개 드라이버가 없으므로 0개 사례가 실제 출력된 것은 아니다. 쿼리 구조는 해당 드라이버를 제외하지 않는다.

### 내 말로 정리·이해 확인

막스의 기록된 랩 51개 중 110초 미만은 42개이고, 나머지 9개는 110초 이상이다.

---

## 문제 4. 팀별 110초 미만 랩 비율

### 선정 기준의 이유와 해석 한계

팀 전체 기록이 80개 이상이라는 학습용 선정 조건입니다. 두 드라이버에게 각각 40개 이상을 요구하는 조건과는 다릅니다. 소속 드라이버 중 한 명의 기록이 적어도 합계가 80개면 포함됩니다. 80과 110초는 공식 성능 기준이 아니며, 110초 미만 비율은 팀의 모든 해당 랩을 합친 비율이지 드라이버 비율의 단순 평균이 아닙니다. 공식 팀 순위나 실력 비교로 해석하지 않습니다.

### 테이블 설명

<b>`laps`</b>

한 행의 의미: 특정 세션에서 드라이버 한 명이 주행한 한 랩.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| lap_number | INT | 불가 | 해당 드라이버의 랩 순번. 1은 첫 번째 랩 |
| lap_duration | DECIMAL(12,3) | 허용 | 한 랩을 도는 데 걸린 시간(초). 109.236은 109.236초 |

<b>`drivers`</b>

한 행의 의미: 세션에 참가한 드라이버 한 명.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| full_name | VARCHAR(100) | 허용 | 드라이버 이름 |
| team_name | VARCHAR(100) | 허용 | 드라이버의 소속 팀 이름 |

<b>두 테이블의 관계:</b> session_key와 driver_number가 모두 같은 행은 같은 세션의 같은 드라이버를 나타냅니다. 드라이버 한 명의 정보에 여러 랩 기록이 연결될 수 있습니다.

### 문제

laps와 drivers를 이용하여 <b>팀별로</b> 기록된 랩 수, 110초 미만 랩 수, 110초 미만 랩 비율을 조회하는 SQL문을 작성해 주세요.

팀의 기록된 랩은 소속 드라이버들의 랩을 모두 합하여 계산합니다.

### 조건

- lap_details는 사용하지 않습니다.
- 기록된 랩이 팀 전체에서 80개 이상인 팀만 출력합니다. 정확히 80개인 팀도 포함합니다.
- 개별 드라이버에게 40개 등의 최소 랩 수 조건을 적용하지 않습니다.
- NULL 랩타임은 전체 기록 수와 110초 미만 기록 수에 포함하지 않습니다.
- 정확히 110초인 랩은 110초 미만 랩에 포함하지 않습니다.
- 비율(%) = 팀의 110초 미만 랩 수 ÷ 팀의 기록된 전체 랩 수 × 100.
- 비율은 소수점 둘째 자리까지 반올림합니다.
- 110초 미만 랩이 없는 팀도 전체 기록 수가 80개 이상이면 포함하고, 해당 건수·비율을 0으로 표시합니다.
- 반올림한 비율 내림차순, 같으면 팀 이름 오름차순으로 정렬합니다.

<b>결과 한 행의 의미:</b> 팀 하나의 랩 통계. 드라이버별 행이 아닙니다.

### 출력 컬럼

| 컬럼명 | 의미 |
| --- | --- |
| team_name | 소속 팀 이름 |
| timed_lap_count | 팀 소속 드라이버들의 기록된 랩 수 합계 |
| under_110_count | 팀 소속 드라이버들의 110초 미만 랩 수 합계 |
| under_110_rate | 110초 미만 랩 비율(%), 소수점 둘째 자리까지 반올림 |

### 출력 예시 — 가상 데이터

아래는 실제 바쿠 실행 결과가 아닌 가상 결과입니다.

| team_name | timed_lap_count | under_110_count | under_110_rate |
| --- | --- | --- | --- |
| Team A | 100 | 80 | 80.00 |
| Team B | 90 | 63 | 70.00 |
| Team C | 85 | 0 | 0.00 |

### 예시 설명

Team A의 두 드라이버가 각각 50개씩 기록하고 그중 40개씩이 110초 미만이라면, 팀 전체는 100개 중 80개이므로 80.00%입니다. Team C는 110초 미만 랩이 없어도 기록된 전체 랩이 85개이므로 포함됩니다.

### 내 첫 시도

```sql
SELECT d.team_name,
    COUNT(l.lap_durtion) AS timed_lap_count,
    COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END) AS under_110_count,
    ROUND(under_110_count / timed_lap_count * 100, 2) AS under_110_rate
FORM drivers d
JOIN laps l ON l.session_key = d.session_key AND l.driver_number = d.driver_number
GROUP BY l.driver_number, d.full_name, d.team_name
HAVING timed_lap_count >= 80
ORDER BY under_110_rate DESC, team_name ASC;
```

### 실행 결과·오류

첫 시도의 실제 오류 메시지는 제출되지 않았다. 코드 검토에서 오타, 같은 SELECT 목록의 별칭 참조, 드라이버 단위 GROUP BY를 발견했다. 두 번째 시도에서 팀별 GROUP BY와 집계식 반복은 수정했으나 오타가 남았다.

### 틀린 이유

팀별 통계에 드라이버 번호·이름까지 묶으면 팀 전체가 아닌 드라이버별 통계가 된다. MySQL은 같은 SELECT 목록에서 정의한 별칭을 다른 계산식에 바로 사용할 수 없다. HAVING·ORDER BY에서는 별칭 사용 가능하다. lap_durtion과 FORM도 수정했다.

### 수정 쿼리

```sql
SELECT d.team_name,
    COUNT(l.lap_duration) AS timed_lap_count,
    COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END) AS under_110_count,
    ROUND(
        COUNT(CASE WHEN l.lap_duration < 110 THEN 1 END)
        / COUNT(l.lap_duration) * 100, 2
    ) AS under_110_rate
FROM drivers d
JOIN laps l
    ON l.session_key = d.session_key
   AND l.driver_number = d.driver_number
GROUP BY d.team_name
HAVING timed_lap_count >= 80
ORDER BY under_110_rate DESC, team_name ASC;
```

### 검증

실행 결과: 9 rows in set (0.03 sec).

| team_name | timed_lap_count | under_110_count | under_110_rate |
| --- | --- | --- | --- |
| Red Bull Racing | 102 | 84 | 82.35 |
| Ferrari | 102 | 80 | 78.43 |
| Mercedes | 102 | 80 | 78.43 |
| McLaren | 86 | 67 | 77.91 |
| Haas F1 Team | 102 | 73 | 71.57 |
| Racing Bulls | 102 | 71 | 69.61 |
| Audi | 102 | 64 | 62.75 |
| Williams | 80 | 50 | 62.50 |
| Cadillac | 100 | 35 | 35.00 |

Williams의 80개는 경계값을 포함한다. Ferrari·Mercedes는 표시 비율이 같아서 이름순으로 정렬됐다.

### 내 말로 정리·이해 확인

막스 51개·42개 + 하자르 51개·42개 = 레드불 102개·84개. 84 / 102 × 100 = 82.35%. 사람 수가 아니라 두 드라이버의 랩을 합쳐 센다.
</details>

<details>
<summary>🧩 문제 5 — 서브쿼리로 조건을 만족하는 드라이버 수 구하기</summary>

## 문제 5. 110초 미만 랩이 40개 이상인 드라이버 수

### 선정 기준의 이유와 해석 한계

이 문제는 전체 기록 40개 이상이 아니라, 110초 미만으로 기록된 랩 자체가 40개 이상인 드라이버를 세는 조건입니다. 많은 수의 기준 충족 랩을 가진 대상을 고르는 조건부 집계·서브쿼리 연습이며, 40개와 110초는 공식 F1 기준이나 통계적으로 검증된 성능 기준이 아닙니다. 더 많은 랩을 기록할수록 조건 충족 기회도 많아지므로 이 건수만으로 속도·실력·경기 순위를 판단하지 않습니다.

### 테이블 설명

<b>`laps`</b>

한 행의 의미: 특정 세션에서 드라이버 한 명이 주행한 한 랩.

| 컬럼명 | 자료형 | NULL 허용 | 설명 |
| --- | --- | --- | --- |
| session_key | INT | 불가 | 세션 ID. 같은 레이스 세션의 기록을 구분하는 값 |
| driver_number | INT | 불가 | 드라이버 번호. 이름 대신 연결·집계에 사용하는 번호 |
| lap_number | INT | 불가 | 해당 드라이버의 랩 순번. 1은 첫 번째 랩 |
| lap_duration | DECIMAL(12,3) | 허용 | 한 랩을 도는 데 걸린 시간(초). 109.236은 109.236초 |

현재 데이터에는 세션이 하나만 있습니다. 이번 문제는 드라이버 수만 필요하므로 이름·팀 테이블은 사용하지 않습니다.

### 문제

laps에서 <b>110초 미만인 랩이 40개 이상인 드라이버가 몇 명인지</b> 조회하는 SQL문을 작성해 주세요.

### 조건

- 드라이버별로 110초 미만인 랩 수를 판단합니다.
- 정확히 110초인 랩과 NULL 랩타임은 해당 랩 수에 포함하지 않습니다.
- 110초 미만 랩이 정확히 40개인 드라이버도 포함합니다.
- 전체 기록된 랩 수가 40개 이상이라는 P3의 조건과 다릅니다. 이 문제에서는 110초 미만인 랩 자체가 40개 이상이어야 합니다.
- 드라이버 목록이나 랩 수 합계가 아니라, 조건을 만족한 드라이버의 수만 출력합니다.
- 결과는 한 행이며 정렬 조건은 없습니다.
- 조건을 만족하는 드라이버가 없으면 0을 출력합니다.

<b>결과 한 행의 의미:</b> 조건을 만족하는 전체 드라이버 수를 담은 최종 집계.

### 출력 컬럼

| 컬럼명 | 의미 |
| --- | --- |
| driver_count | 110초 미만인 랩이 40개 이상인 드라이버 수 |

### 예시 — 가상 집계와 출력

다음 표는 원본 laps가 아니라, 가상의 랩 기록을 드라이버별로 요약한 설명용 표입니다.

| driver_number | 110초 미만 랩 수 |
| --- | --- |
| 7 | 42 |
| 12 | 40 |
| 3 | 39 |

출력 예시:

| driver_count |
| --- |
| 2 |

### 예시 설명

7번은 42개, 12번은 40개이므로 조건을 만족합니다. 3번은 39개라 제외합니다. 최종 출력은 랩 수 82가 아니라 드라이버 수 2입니다.

### 내 첫 시도

```sql
SELECT COUNT(under_110_count) AS driver_count
FROM laps (SELECT COUNT(CASE WHEN lap_duration < 110 THEN 1 ELSE 0 END)
FROM laps
GROUP BY driver_number
WHERE lap_duration NOT IN ('NULL')
) AS under_110_count
GROUP BY driver_number
HAVING under_110_count >= 40;
```

### 실행 결과·오류

중첩 SELECT가 불필요하게 추가된 부분을 제거하고, 안쪽 그룹별 집계와 바깥 COUNT를 분리했습니다. 첫 시도의 실행 결과·오류 메시지는 기록되지 않았습니다.

### 틀린 이유

FROM laps (SELECT ...)는 서브쿼리 문법이 아니다. COUNT의 ELSE 0은 불일치 행도 세게 한다. 'NULL' 문자열은 SQL NULL이 아니며, 이번 CASE의 비교 조건만으로 NULL 랩이 제외된다. WHERE는 GROUP BY보다 앞에 쓰지만 이번에는 별도 WHERE가 필요하지 않다. 40개 조건은 안쪽 HAVING에서 적용하고, 바깥에서는 남은 드라이버 행만 센다.

### 최종 쿼리

```sql
SELECT COUNT(*) AS driver_count
FROM (
    SELECT driver_number,
        COUNT(CASE WHEN lap_duration < 110 THEN 1 END) AS under_110_count
    FROM laps
    GROUP BY driver_number
    HAVING under_110_count >= 40
) AS qualifying_drivers;
```

### 검증

| driver_count |
| --- |
| 6 |

실행 결과: 1 row in set (0.08 sec).

P3 결과에서 막스·하자르·러셀 각 42개, 피아스트리 41개, 르클레르·해밀턴 각 40개로 총 6명임을 대조했다. 이번 업로드에서 AI의 별도 DB 재실행은 하지 않았다.

### 핵심 개념 정리

안쪽은 드라이버별 랩 수를 계산해 조건을 만족하는 드라이버만 남긴다. 바깥 COUNT는 그 중간 결과의 행 수, 즉 드라이버 수를 센다.

### 서브쿼리 한 행의 의미

| 단계 | 한 행의 의미 | 집계 대상 |
| --- | --- | --- |
| 원본 laps | 드라이버 한 명의 한 랩 | 랩 |
| 안쪽 GROUP BY·HAVING 결과 | 조건을 만족하는 드라이버 한 명 | 드라이버별 랩 수 |
| 바깥 SELECT 결과 | 최종 집계 한 행 | 남은 드라이버 행 수 |

이는 이해를 위한 논리적 처리 흐름이다. 실제 DB의 물리적 실행 순서를 단정하지 않는다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — JOIN 키·COUNT·팀 비율·한 행의 의미</summary>

## COUNT·NULL·조건부 집계

| 표현 | 세는 대상 |
| --- | --- |
| COUNT(\\\*) | 모든 행 |
| COUNT(lap_duration) | 랩타임이 NULL이 아닌 행 |
| COUNT(lap_duration \&lt; 110) | 비교 결과가 NULL이 아닌 행: 1과 0 모두 |
| COUNT(CASE WHEN 조건 THEN 1 END) | 조건을 만족한 행 |

CASE에서 ELSE 생략 시 불일치 행은 NULL이다. COUNT는 NULL을 제외하므로 원하는 행만 센다. COUNT 안의 ELSE 0과 SUM 안의 ELSE 0을 혼동하지 않는다.

## JOIN 조건은 어떻게 알아내는가?

먼저 한 행의 의미와 키를 확인한다. drivers의 기본키는 session_key + driver_number다. laps에 정확한 드라이버 정보를 붙이려면 두 값이 모두 같아야 한다.

```sql
ON l.session_key = d.session_key
AND l.driver_number = d.driver_number
```

드라이버 번호만 연결하면 여러 세션에서 정보가 섞일 수 있다. 세션만 연결하면 다른 드라이버와도 연결된다. INNER JOIN 작성 순서와 조건은 별개다. 이번 연결은 laps부터 작성해도 된다.

## GROUP BY와 비율의 분모

결과 한 행이 드라이버면 드라이버별로, 팀이면 팀별로 묶는다. 팀별 랩 비율에서는 팀 소속 드라이버의 랩을 합산한다.

| 레드불 | 기록된 랩 | 110초 미만 랩 |
| --- | --- | --- |
| 막스 | 51 | 42 |
| 하자르 | 51 | 42 |
| 합계 | 102 | 84 |

84 / 102 × 100 = 82.35%. 평균 드라이버 비율을 단순 평균한 것이 아니라 랩 수를 합쳐 계산한 비율이다.

## 해석의 한계

110초 기준은 SQL 연습을 위한 분류 기준이다. 피트·세이프티카·교통·타이어 등의 맥락을 통제하지 않았으므로 팀이나 드라이버의 실력을 확정하지 않는다. NULL은 0초가 아니다.
</details>

<details>
<summary>🧠 오늘의 회고·검증 범위·재풀이</summary>

## 해결 상태

| 문제 | 실행 결과 |
| --- | --- |
| P1 | 16행 |
| P2 | 16행 |
| P3 | 16행 |
| P4 | 9행 |
| P5 | 6명 |

5문제의 MySQL 실행 결과를 확인했습니다.

## 확인된 진행

드라이버 집계·복합 JOIN·조건부 집계·팀 비율·서브쿼리의 실행 결과를 확인했습니다. 전체 기록 랩 수와 특정 시간 미만 랩 수는 서로 다른 집계값입니다.

## 아직 복습할 부분

문장 속 조건을 집계 대상으로 옮기는 과정, JOIN 키 판단, GROUP BY 단위, 조건부 COUNT의 NULL, 서브쿼리 구조를 빈 화면에서 선택하는 과정.

## 답을 보지 않고 다시 풀 문제

P5의 기준을 바꾸어 110초 미만 랩이 35개 이상인 드라이버 수를 조회한다.

- [ ] 안쪽 쿼리의 한 행 의미 먼저 적기
- [ ] 드라이버별 조건부 랩 수 계산
- [ ] HAVING으로 드라이버 선별
- [ ] 바깥 COUNT로 드라이버 수 계산

<b>재풀이 상태: 미실행.</b>

## 기록 방식

문제는 프로그래머스 형식의 테이블 설명 → 문제 → 출력 컬럼 → 가상 예시로 제시한다. 힌트는 제출 코드 검토 후 제공한다. 앞으로도 업로드 전 최근 SQL TIL의 Day 번호·토글·문제별 항목을 먼저 확인하고 동일한 양식을 따른다.
</details>
</details>
