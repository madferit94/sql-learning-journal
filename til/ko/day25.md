# Day 25 — 팀별 상위 대상·다단계 CTE·ROW_NUMBER·대표 거래

[English](../en/day25.md) · [목차](../../README.ko.md)

금융 결과의 고객·거래 ID는 공개본에서 일관된 가명으로 바꿨습니다. 정렬은 원본 ID 기준 실행 결과의 행 순서를 유지하며 가명 문자열 순서로 재정렬하지 않았습니다. 날짜·금액·SQL은 유지했습니다. 노션은 제출 기록의 원래 ID를 보존합니다.

<details>
<summary>🏎️💳 Day25 — 팀별 상위 대상·다단계 CTE·ROW_NUMBER·대표 거래 선택</summary>

# SQL 학습 기록 — Day 25

## 학습 개요

- 환경: MySQL / f1_study·finance
- 1~3번: 브라질까지 본선 20경기, 소속 팀 NULL 제외
- 4~5번: 금융 거래 전체, 날짜 기준 대표 거래 선택
- 범위: 팀별 순위 복습·순위 계산 후 필터·ROW_NUMBER·분야 전환
- 제출 SQL과 공유된 출력에 근거합니다. 미공유 오류 메시지·전체 행 수·시간은 추정하지 않습니다.

## 접속

일반 터미널:

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

mysql> 화면:

```sql
USE f1_study;
-- 문제 4~5:
USE finance;
```

<details>
<summary>🏁 문제 1 — 팀별 드라이버 누적 포인트 순위</summary>

## 문제 1. 팀별 드라이버 누적 포인트 순위

### 테이블과 한 행의 의미

drivers는 특정 경기의 드라이버 한 명, race_results는 그 경기의 드라이버별 최종 결과 한 행입니다. 두 테이블의 키는 session_key + driver_number이며 두 키로 연결합니다.

| 테이블 | 컬럼 | 타입 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 번호, NULL 불가 |
| race_results | points | DECIMAL(8,2) | 본선 포인트, 현재 실제 NULL 없음 |

필요한 컬럼 일부입니다. 전체 20개 본선이며, DNS·DNF·0점 등록도 포함합니다. 공식 챔피언십 순위와 구분합니다.

### 문제와 조건

CTE와 RANK로 전체 20개 본선의 팀·드라이버별 등록 경기 수와 포인트 합계, 팀 내 순위를 조회합니다.

- team_name NULL 제외; 소속 누락 보완은 하지 않습니다.
- 팀 이름·번호·이름으로 집계하고 이적 시 팀별로 나눕니다.
- 동점 공동 순위, 다음 순위 건너뜀.
- 팀 이름 → 팀 내 순위 → 드라이버 번호 모두 오름차순.
- 전원 출력하며 한 행은 팀·드라이버 조합입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 소속 팀 |
| team_rank | 팀 내 순위 |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| race_count | 해당 팀 등록 경기 수 |
| total_points | 해당 팀 포인트 합계 |

### 가상 예시 — 실제 결과 아님

가상 한 팀의 점수가 100·80·80·50이면 순위는 1·2·2·4입니다.

### 최종 SQL

```sql
WITH f1_race AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.full_name, d.driver_number
)
SELECT team_name,
       RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
       driver_number, full_name, race_count, total_points
FROM f1_race
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### 실제 실행 결과 — 전체 공유 행

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

공유된 결과 하단이 잘려 최종 행 수·실행 시간은 기록하지 않습니다.

### 수정 이유와 이해할 부분

처음에는 PARTITION BY가 빠져 전체 순위를 계산했습니다. 팀별 비교 집단을 지정하고 팀·번호·이름으로 집계하도록 수정했습니다. 최종 ORDER BY만으로는 팀별 순위를 만들 수 없습니다. 미공유 DB 오류 메시지는 기록하지 않습니다.
</details>

<details>
<summary>🧩 문제 2 — 팀별 누적 포인트 2위 이내 조회</summary>

## 문제 2. 팀별 누적 포인트 2위 이내 조회

### 테이블과 한 행의 의미

drivers는 특정 경기의 드라이버 한 명, race_results는 그 경기의 드라이버별 최종 결과 한 행입니다. 두 테이블의 키는 session_key + driver_number이며 두 키로 연결합니다.

| 테이블 | 컬럼 | 타입 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 번호, NULL 불가 |
| race_results | points | DECIMAL(8,2) | 본선 포인트, 현재 실제 NULL 없음 |

필요한 컬럼 일부입니다. 전체 20개 본선이며, DNS·DNF·0점 등록도 포함합니다. 공식 챔피언십 순위와 구분합니다.

### 문제와 조건

문제 1과 같은 범위·집계·NULL 제외 기준으로 RANK 순위 2위 이내만 조회합니다.

- 공동 2위 모두 포함하며 팀당 정확히 2명이라는 뜻은 아닙니다.
- 팀 이름 → 팀 내 순위 → 드라이버 번호 모두 오름차순.
- 한 행은 조건을 통과한 팀·드라이버 조합입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 소속 팀 |
| team_rank | 팀 내 순위 |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| race_count | 해당 팀 등록 경기 수 |
| total_points | 해당 팀 포인트 합계 |

### 가상 예시 — 실제 결과 아님

가상 100·80·80점 팀의 2위 이내는 3명입니다.

### 최종 SQL

```sql
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number, d.full_name
),
2026_top2_rank AS (
    SELECT team_name,
           RANK() OVER (PARTITION BY team_name ORDER BY total_points DESC) AS team_rank,
           driver_number, full_name, race_count, total_points
    FROM 2026_f1
)
SELECT team_name, team_rank, driver_number, full_name, race_count, total_points
FROM 2026_top2_rank
WHERE team_rank <= 2
ORDER BY team_name ASC, team_rank ASC, driver_number ASC;
```

### 실제 실행 결과 — 전체 공유 행

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
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

22 rows in set (0.11 sec)

### 수정 이유와 이해할 부분

처음 같은 SELECT의 HAVING team_rank <= 2로 필터링하려 했습니다. 윈도우 함수 결과를 계산한 뒤 선택해야 하므로 순위 CTE를 추가했습니다. 집계 → 팀별 순위 → 바깥 WHERE의 세 단계입니다. 현재 22행이어도 공동 2위가 여러 명이면 팀당 2명을 넘을 수 있습니다.
</details>

<details>
<summary>🏁 문제 3 — 팀별 누적 포인트 상위 최대 2명</summary>

## 문제 3. 팀별 누적 포인트 상위 최대 2명

### 테이블과 한 행의 의미

drivers는 특정 경기의 드라이버 한 명, race_results는 그 경기의 드라이버별 최종 결과 한 행입니다. 두 테이블의 키는 session_key + driver_number이며 두 키로 연결합니다.

| 테이블 | 컬럼 | 타입 | 설명 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 ID, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 이름, NULL 허용 |
| drivers | team_name | VARCHAR(100) | 소속 팀, NULL 허용 |
| race_results | session_key | INT | 세션 ID, NULL 불가 |
| race_results | driver_number | INT | 번호, NULL 불가 |
| race_results | points | DECIMAL(8,2) | 본선 포인트, 현재 실제 NULL 없음 |

필요한 컬럼 일부입니다. 전체 20개 본선이며, DNS·DNF·0점 등록도 포함합니다. 공식 챔피언십 순위와 구분합니다.

### 문제와 조건

문제 1과 같은 범위·집계·NULL 제외 기준으로 각 팀에서 최대 2명을 선택합니다.

- ROW_NUMBER 사용. 팀 안 포인트 내림차순, 동점은 드라이버 번호 오름차순으로 번호 부여.
- 번호 1·2만 선택하고 동점 추가 인원은 포함하지 않습니다. 한 명뿐인 팀은 한 명만 출력합니다.
- 팀 이름 → 선택 번호 모두 오름차순.
- 한 행은 선택한 팀·드라이버 조합이며 selection_no는 공식 순위가 아닙니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 소속 팀 |
| selection_no | 고유 선택 번호 |
| driver_number | 드라이버 번호 |
| full_name | 이름 |
| race_count | 해당 팀 등록 경기 수 |
| total_points | 해당 팀 포인트 합계 |

### 가상 예시 — 실제 결과 아님

가상 8번 100점·25번 80점·31번 80점이면 8번과 25번만 선택합니다.

### 최종 SQL

```sql
WITH 2026_f1 AS (
    SELECT d.team_name, d.driver_number, d.full_name,
           COUNT(*) AS race_count, SUM(r.points) AS total_points
    FROM drivers d
    JOIN race_results r
        ON r.driver_number = d.driver_number
       AND r.session_key = d.session_key
    WHERE d.team_name IS NOT NULL
    GROUP BY d.team_name, d.driver_number, d.full_name
),
f1_selection AS (
    SELECT team_name,
           ROW_NUMBER() OVER (
               PARTITION BY team_name
               ORDER BY total_points DESC, driver_number ASC
           ) AS selection_no,
           driver_number, full_name, race_count, total_points
    FROM 2026_f1
)
SELECT team_name, selection_no, driver_number, full_name, race_count, total_points
FROM f1_selection
WHERE selection_no <= 2
ORDER BY team_name ASC, selection_no ASC;
```

### 실제 실행 결과 — 전체 공유 행

| team_name | selection_no | driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- | --- | --- |
| Alpine | 1 | 10 | Pierre GASLY | 20 | 40.00 |
| Alpine | 2 | 43 | Franco COLAPINTO | 20 | 27.00 |
| Aston Martin | 1 | 14 | Fernando ALONSO | 20 | 7.00 |
| Aston Martin | 2 | 18 | Lance STROLL | 20 | 0.00 |
| Audi | 1 | 5 | Gabriel BORTOLETO | 20 | 14.00 |
| Audi | 2 | 27 | Nico HULKENBERG | 20 | 12.00 |
| Cadillac | 1 | 11 | Sergio PEREZ | 20 | 0.00 |
| Cadillac | 2 | 77 | Valtteri BOTTAS | 20 | 0.00 |
| Ferrari | 1 | 44 | Lewis HAMILTON | 20 | 234.00 |
| Ferrari | 2 | 16 | Charles LECLERC | 20 | 215.00 |
| Haas F1 Team | 1 | 87 | Oliver BEARMAN | 20 | 19.00 |
| Haas F1 Team | 2 | 31 | Esteban OCON | 18 | 7.00 |
| McLaren | 1 | 1 | Lando NORRIS | 20 | 213.00 |
| McLaren | 2 | 81 | Oscar PIASTRI | 20 | 131.00 |
| Mercedes | 1 | 12 | Kimi ANTONELLI | 20 | 359.00 |
| Mercedes | 2 | 63 | George RUSSELL | 20 | 228.00 |
| Racing Bulls | 1 | 30 | Liam LAWSON | 17 | 68.00 |
| Racing Bulls | 2 | 41 | Arvid LINDBLAD | 20 | 37.00 |
| Red Bull Racing | 1 | 3 | Max VERSTAPPEN | 20 | 259.00 |
| Red Bull Racing | 2 | 6 | Isack HADJAR | 17 | 122.00 |
| Williams | 1 | 55 | Carlos SAINZ | 20 | 7.00 |
| Williams | 2 | 23 | Alexander ALBON | 20 | 5.00 |

22 rows in set (0.07 sec)

### 수정 이유와 이해할 부분

번호 부여·선택은 맞았고 최종 출력 정렬을 포인트순에서 팀 이름·선택 번호순으로 수정했습니다. OVER 안 ORDER BY는 선택 기준, 마지막 ORDER BY는 표시 순서입니다. Cadillac의 0점 두 명은 RANK에서 공동 1위지만 ROW_NUMBER에서는 11번 1·77번 2로 구분됩니다.
</details>

<details>
<summary>🏁 문제 4 — 고객별 최근 거래일의 대표 거래 1건</summary>

## 문제 4. 고객별 최근 거래일의 대표 거래 1건

### 테이블과 한 행의 의미

bank_transactions의 한 행은 거래 한 건입니다. 필요한 컬럼 일부입니다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키·NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 불가 |
| transaction_date | DATE | 거래 날짜, NULL 불가 |
| transaction_amount | DECIMAL(15,2) | 거래 금액, NULL 불가 |

통화는 이번 문제에서 확정하지 않았습니다. 거래 시각은 사용하지 않으며 같은 날짜 안의 실제 마지막 거래를 찾는 문제가 아닙니다.

### 문제와 조건

bank_transactions만 사용해 고객별 최근 거래일의 대표 거래 한 건을 선택합니다.

- ROW_NUMBER 사용; 고객별 거래 날짜 내림차순 → 금액 내림차순 → 거래 ID 문자열 오름차순으로 선택합니다.
- 거래 한 건인 고객도 포함하고 원본 거래 금액을 출력합니다. 고객별 합산은 하지 않습니다.
- 거래 시각은 사용하지 않습니다.
- 고객 ID 오름차순이며 한 행은 고객별 대표 거래 한 건입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| transaction_id | 선택한 거래 ID |
| transaction_date | 선택한 거래 날짜 |
| transaction_amount | 선택한 거래 금액 |

### 가상 예시 — 실제 결과 아님

가상 C01의 과거 9,000 거래와 최근 날짜 500·800 거래 중 최근 날짜의 800 거래를 선택합니다.

### 최종 SQL

```sql
WITH recent_transaction AS (
    SELECT customer_id, transaction_id, transaction_date, transaction_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY transaction_date DESC,
                        transaction_amount DESC,
                        transaction_id ASC
           ) AS rn
    FROM bank_transactions
)
SELECT customer_id, transaction_id, transaction_date, transaction_amount
FROM recent_transaction
WHERE rn <= 1
ORDER BY customer_id ASC;
```

### 실제 실행 결과 — 공유된 앞부분 발췌

| customer_id | transaction_id | transaction_date | transaction_amount |
| --- | --- | --- | --- |
| CUSTOMER_001 | TXN_007 | 2016-09-26 | 4750.00 |
| CUSTOMER_002 | TXN_009 | 2016-08-14 | 1499.00 |
| CUSTOMER_003 | TXN_006 | 2016-08-07 | 250.00 |
| CUSTOMER_004 | TXN_022 | 2016-09-15 | 30.00 |
| CUSTOMER_005 | TXN_011 | 2016-08-18 | 5000.00 |
| CUSTOMER_006 | TXN_018 | 2016-08-29 | 557.00 |
| CUSTOMER_007 | TXN_003 | 2016-08-04 | 1460.00 |
| CUSTOMER_008 | TXN_014 | 2016-08-27 | 700.00 |
| CUSTOMER_009 | TXN_017 | 2016-08-26 | 208.00 |
| CUSTOMER_010 | TXN_005 | 2016-08-09 | 19680.00 |
| CUSTOMER_011 | TXN_021 | 2016-09-07 | 100.00 |

공유된 출력 일부만 수록합니다. 전체 행 수·실행 시간은 공유되지 않았습니다.

### 수정 이유와 이해할 부분

처음 날짜 다음에 거래 ID 내림차순을 사용해 금액 기준이 빠졌습니다. 수정 기준을 마지막 ORDER BY에 넣었다가, ROW_NUMBER 안의 정렬로 옮겼습니다. 최종 출력은 고객 ID 오름차순으로 유지했습니다. 앞부분 출력이 같아도 같은 날짜의 여러 거래에 대해 선택 기준을 보장하는지가 중요합니다.
</details>

<details>
<summary>🏁 문제 5 — 대표 거래 금액이 5,000 이상인 고객</summary>

## 문제 5. 대표 거래 금액이 5,000 이상인 고객

### 테이블과 한 행의 의미

bank_transactions의 한 행은 거래 한 건입니다. 필요한 컬럼 일부입니다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키·NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 불가 |
| transaction_date | DATE | 거래 날짜, NULL 불가 |
| transaction_amount | DECIMAL(15,2) | 거래 금액, NULL 불가 |

통화는 이번 문제에서 확정하지 않았습니다. 거래 시각은 사용하지 않으며 같은 날짜 안의 실제 마지막 거래를 찾는 문제가 아닙니다.

### 문제와 조건

고객별 대표 거래를 전체 거래에서 먼저 고른 뒤, 그 금액이 5,000 이상인 고객만 조회합니다.

- 대표 선택 기준은 거래 날짜 내림차순 → 금액 내림차순 → 거래 ID 문자열 오름차순입니다.
- ROW_NUMBER 사용, bank_transactions만 사용하며 시각은 사용하지 않습니다.
- 대표 거래가 5,000 미만이면 과거 고액 거래가 있어도 제외합니다. 경계값 5,000은 포함합니다.
- 최종 금액 내림차순 → 고객 ID 오름차순.
- 한 행은 조건을 통과한 고객의 대표 거래입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| transaction_id | 선택한 거래 ID |
| transaction_date | 선택한 거래 날짜 |
| transaction_amount | 선택한 거래 금액 |

### 가상 예시 — 실제 결과 아님

가상 C01은 과거 9,000·최근 500이면 제외합니다. C02 대표 7,000과 C03 대표 5,000은 포함합니다.

### 최종 SQL

```sql
WITH recent_transaction AS (
    SELECT customer_id, transaction_id, transaction_date, transaction_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY transaction_date DESC,
                        transaction_amount DESC,
                        transaction_id ASC
           ) AS rn
    FROM bank_transactions
)
SELECT customer_id, transaction_id, transaction_date, transaction_amount
FROM recent_transaction
WHERE transaction_amount >= 5000 AND rn <= 1
ORDER BY transaction_amount DESC, customer_id ASC;
```

### 실제 실행 결과 — 공유된 앞부분 발췌

| customer_id | transaction_id | transaction_date | transaction_amount |
| --- | --- | --- | --- |
| CUSTOMER_021 | TXN_010 | 2016-08-18 | 1560034.99 |
| CUSTOMER_020 | TXN_016 | 2016-08-22 | 1380002.88 |
| CUSTOMER_015 | TXN_013 | 2016-08-23 | 991132.22 |
| CUSTOMER_013 | TXN_015 | 2016-08-03 | 720001.16 |
| CUSTOMER_019 | TXN_020 | 2016-09-09 | 600008.32 |
| CUSTOMER_017 | TXN_004 | 2016-08-04 | 600003.45 |
| CUSTOMER_016 | TXN_008 | 2016-08-14 | 569500.27 |
| CUSTOMER_012 | TXN_002 | 2016-08-05 | 561001.00 |
| CUSTOMER_018 | TXN_012 | 2016-08-18 | 557000.73 |
| CUSTOMER_014 | TXN_001 | 2016-09-13 | 550004.34 |
| CUSTOMER_022 | TXN_019 | 2016-09-06 | 543699.36 |

공유된 출력 일부만 수록합니다. 전체 행 수·실행 시간은 공유되지 않았습니다.

### 수정 이유와 이해할 부분

전체 거래에서 번호를 계산하고 바깥 WHERE에서 금액과 rn 조건을 함께 적용했습니다. AND로 연결한 두 조건의 작성 순서는 결과를 바꾸지 않습니다. ROW_NUMBER는 1부터 시작하므로 rn <= 1과 rn = 1은 같지만 rn >= 1은 모든 거래를 통과시켜 대표 거래 조건이 사라집니다.
</details>

<details>
<summary>🔎 이해 정리·복습 — 순위와 번호·정렬·필터 시점</summary>

## RANK와 ROW_NUMBER

RANK는 동점 공동 순위를 유지합니다. ROW_NUMBER는 동점에서도 서로 다른 번호를 붙입니다. 최대 N명을 선택할 때는 결과가 결정되도록 동점 정렬 기준이 필요합니다.

| 가상 포인트 | RANK | ROW_NUMBER |
| --- | --- | --- |
| 100 | 1 | 1 |
| 80 | 2 | 2 |
| 80 | 2 | 3 |
| 50 | 4 | 4 |

## UNION ALL 예시의 역할

실제 테이블 없이 가상 행을 만들어 위아래로 이어 붙이기 위한 예시였습니다. 중복을 유지하며, ROW_NUMBER에 필수인 문법이 아닙니다. 예시를 실행했다는 결과는 공유되지 않아 실행 완료로 기록하지 않습니다.

## 두 ORDER BY와 필터 시점

- OVER 안 ORDER BY: 누구에게 앞 번호를 부여하고 어떤 행을 선택할지 결정합니다.
- 마지막 ORDER BY: 선택된 행을 표시할 순서입니다.
- 계산된 순위를 필터링하려면 다음 쿼리 단계에서 선택합니다.
- 대표 거래를 전체 거래에서 고른 후 금액 조건을 적용해야 과거 고액 거래로 대체되지 않습니다.
- rn은 1부터 시작합니다. rn >= 1은 대표 한 건을 고르는 조건이 아닙니다.

## 복습 체크

- [ ] 공동 2위 포함과 최대 2명 선택의 차이 설명하기
- [ ] 집계·번호 계산·최종 필터의 한 행 의미 설명하기
- [ ] 대표 거래 선택 기준과 최종 출력 정렬 구분하기
- [ ] 다른 날짜·동점 가상 데이터로 독립 재풀이하기

다음 독립 재풀이는 아직 확인하지 않았습니다.
</details>
</details>