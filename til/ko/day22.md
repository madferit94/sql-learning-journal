# 🏎️🛒 Day22 — F1 복습·이커머스 CTE·고객 구매금액 순위

[English](../en/day22.md) · [목차](../../README.ko.md) · [검증 기록](../../docs/audit.ko.md)

<details>
<summary>🏎️🛒 Day22 — F1 복습·이커머스 CTE·고객 구매금액 순위</summary>

# SQL 학습 기록 — Day 22

## 학습 개요

<b>환경:</b> MySQL / f1_study·retail_study
<b>범위:</b> F1 팀 집계·누적 포인트 복습 → 이커머스 고객 집계·CTE·RANK·PARTITION BY
<b>검증 근거:</b> 제출된 최종 SQL과 MySQL 실행 결과. 3\~5번은 공유된 출력 일부만 수록하며 전체 행 수·실행 시간을 추정하지 않습니다. 게시를 위해 문제 SQL을 다시 실행하지 않았습니다.

### 데이터 범위와 해석

- F1은 멕시코 본 레이스 추가로 19경기입니다. drivers와 race_results는 각각 418행입니다.
- 1번은 오스틴 11396만 조회합니다. 2번은 멕시코 11404까지 전체 19경기를 집계합니다.
- 스프린트·예선·연습은 포함하지 않습니다. 포인트 합계는 공식 챔피언십 전체 점수와 구분합니다.
- 이번 F1 문제에는 40랩 선정 조건이 없습니다.
- 멕시코 추가 시 기존 18경기 행을 보존했고 공식 순위·완료 랩·포인트 66개 값의 차이는 0건이었습니다.
- 3\~5번은 retail_study.sales_items의 전체 기간 판매 내역입니다. 고객 미확인 기록은 제외하며, 이 뷰의 구매금액은 반품·취소를 차감한 순매출과 구분합니다.
- 국가별 순위는 구매 기록의 국가 기준입니다. 고객의 고정된 거주국으로 단정하지 않습니다.

### 접속

일반 터미널에서 접속합니다.

```bash
mysql -u root -p
```

mysql> 화면에서 문제에 맞게 데이터베이스를 선택합니다.

```sql
-- 문제 1~2
USE f1_study;

-- 문제 3~5
USE retail_study;
```

<details>
<summary>📚 문제 1 — 오스틴 GP 팀별 집계</summary>

## 문제 1. 오스틴 GP 팀별 결과 집계

### 테이블 설명

drivers의 한 행은 특정 경기의 드라이버 한 명이고, race_results의 한 행은 특정 경기의 드라이버별 최종 결과입니다. 필요한 컬럼만 표시합니다.

| 테이블 | 컬럼 | 타입 | 의미 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 식별자, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 드라이버 이름 |
| drivers | team_name | VARCHAR(100) | 해당 경기의 소속 팀 |
| race_results | session_key | INT | 세션 식별자, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 해당 본 레이스 획득 포인트 |

두 테이블은 session_key와 driver_number의 조합으로 각각 한 행을 구분하며, 두 키로 연결합니다. 현재 결과 데이터의 완료 랩·포인트에는 NULL이 없습니다.

### 문제와 조건

오스틴 GP 결과를 팀별로 집계하여 드라이버 수, 완료 랩 합계, 획득 포인트 합계를 조회합니다.

- 오스틴 세션 11396만 사용합니다.
- 순위가 NULL이거나 0점인 기록도 포함합니다. 최소 랩 수 조건은 없습니다.
- 팀별 포인트 합계 내림차순, 동점이면 팀 이름 오름차순으로 정렬합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| team_name | 팀 이름 |
| driver_count | 해당 팀의 경기 결과 행 수 |
| total_laps | 완료 랩 합계 |
| total_points | 포인트 합계 |

결과 한 행은 오스틴에 참가한 팀 하나입니다.

### 가상 예시와 해설

한 팀의 두 드라이버가 56랩·25점과 56랩·18점을 기록했다면 드라이버 수 2, 완료 랩 112, 포인트 43.00입니다.

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

| team_name | driver_count | total_laps | total_points |
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

실행 결과: 11 rows in set (0.07 sec).

### 핵심 개념과 결과 해석

올바른 두 키 JOIN 이후 한 행은 한 경기의 드라이버 한 명입니다. 팀별 COUNT(\*)가 드라이버 수가 되는 이유입니다. Ferrari는 56 + 56 = 112랩, 18 + 12 = 30점입니다.

JOIN 조건에서 r.driver_number = r.driver_number처럼 같은 테이블 컬럼끼리 비교하면 드라이버를 대응시키지 못합니다. 세션만 같은 모든 결과가 연결되어 행과 합계가 늘어날 수 있으므로 서로 다른 테이블의 식별자를 비교해야 합니다.
</details>

<details>
<summary>🧩 문제 2 — CTE로 누적 100점 이상 드라이버 조회</summary>

## 문제 2. 누적 100점 이상인 드라이버 조회

### 테이블 설명

drivers의 한 행은 특정 경기의 드라이버 한 명이고, race_results의 한 행은 특정 경기의 드라이버별 최종 결과입니다. 필요한 컬럼만 표시합니다.

| 테이블 | 컬럼 | 타입 | 의미 |
| --- | --- | --- | --- |
| drivers | session_key | INT | 세션 식별자, NULL 불가 |
| drivers | driver_number | INT | 드라이버 번호, NULL 불가 |
| drivers | full_name | VARCHAR(100) | 드라이버 이름 |
| drivers | team_name | VARCHAR(100) | 해당 경기의 소속 팀 |
| race_results | session_key | INT | 세션 식별자, NULL 불가 |
| race_results | driver_number | INT | 드라이버 번호, NULL 불가 |
| race_results | completed_laps | INT | 완료 랩 수 |
| race_results | points | DECIMAL(8,2) | 해당 본 레이스 획득 포인트 |

두 테이블은 session_key와 driver_number의 조합으로 각각 한 행을 구분하며, 두 키로 연결합니다. 현재 결과 데이터의 완료 랩·포인트에는 NULL이 없습니다.

### 문제와 조건

멕시코까지 본 레이스 19경기에서 드라이버별 참가 경기 수와 누적 포인트를 구합니다.

- CTE 이름은 driver_totals입니다.
- 드라이버 번호·이름별로 집계하고, 이적 전후 기록은 합산합니다.
- 참가 경기 수는 결과 행 수입니다. 리타이어·0점·숫자 순위가 없는 기록도 포함합니다.
- 누적 포인트가 100 이상인 드라이버만 출력합니다.
- 포인트 내림차순, 동점이면 드라이버 번호 오름차순입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| driver_number | 드라이버 번호 |
| full_name | 드라이버 이름 |
| race_count | 본 레이스 결과 행 수 |
| total_points | 본 레이스 누적 포인트 |

결과 한 행은 조건을 충족한 드라이버 한 명입니다.

### 가상 예시와 해설

19경기에서 150점인 A와 17경기에서 100점인 B는 모두 포함합니다. 최소 참가 경기 수 조건은 없습니다.

### 최종 쿼리

```sql
WITH driver_totals AS (
    SELECT
        d.driver_number,
        d.full_name,
        COUNT(*) race_count,
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

| driver_number | full_name | race_count | total_points |
| --- | --- | --- | --- |
| 12 | Kimi ANTONELLI | 19 | 349.00 |
| 3 | Max VERSTAPPEN | 19 | 241.00 |
| 44 | Lewis HAMILTON | 19 | 232.00 |
| 63 | George RUSSELL | 19 | 216.00 |
| 16 | Charles LECLERC | 19 | 211.00 |
| 1 | Lando NORRIS | 19 | 188.00 |
| 81 | Oscar PIASTRI | 19 | 123.00 |
| 6 | Isack HADJAR | 16 | 107.00 |

실행 결과: 8 rows in set (0.00 sec).

### 핵심 개념과 결과 해석

CTE에서 드라이버별 한 행이 만들어집니다. 바깥 WHERE는 이미 계산된 total_points를 필터링하므로 같은 기준의 GROUP BY를 반복할 필요가 없습니다. 이 합계는 스프린트 점수가 빠진 본 레이스 점수이며 공식 챔피언십 전체 점수와 구분합니다.
</details>

<details>
<summary>🧩 문제 3 — CTE로 누적 구매금액 1,000 이상 고객 조회</summary>

## 문제 3. 누적 구매금액 1,000 이상인 고객 조회

### 테이블 설명

sales_items의 한 행은 청구서에 기록된 상품 내역 한 줄입니다. 한 줄에서 여러 개를 구매할 수 있고, 한 청구서에 여러 줄이 있을 수 있습니다. 수량과 단가가 양수이고 취소 청구서가 아닌 기록만 포함하는 조회용 뷰입니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| country | VARCHAR(100) | 해당 구매 기록의 국가, NULL 없음 |
| quantity | INT | 구매 수량, NULL 없음 |
| unit_price | DECIMAL(16,6) | 상품 한 개의 단가, GBP, NULL 없음 |

한 줄의 구매금액은 quantity × unit_price입니다. 행 수는 상품 수량 합계나 서로 다른 청구서 수와 다릅니다.

### 문제와 조건

고객별 구매 내역 행 수와 누적 구매금액을 구합니다.

- sales_items만 사용하고 고객 ID가 NULL인 기록을 제외합니다.
- 전체 기간을 고객 ID별로 집계하고 CTE 이름은 customer_totals로 지정합니다.
- 누적 구매금액이 1,000 GBP 이상인 고객만 출력합니다.
- 구매금액은 최종 출력에서 소수 둘째 자리까지 반올림합니다.
- 조건 판단과 금액 정렬은 반올림 전 값을 사용합니다.
- 누적 구매금액 내림차순, 동점이면 고객 ID 오름차순입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| item_count | 구매 내역 행 수 |
| total_purchase_amount | 고객별 누적 구매금액, GBP |

결과 한 행은 조건을 충족한 고객 한 명입니다.

### 가상 예시와 해설

C001의 구매 내역이 12줄이고 합계가 2,500 GBP라면 item_count는 12, total_purchase_amount는 2500.00입니다. 12는 상품 수량이나 청구서 수가 아닙니다.

### 최종 쿼리

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        COUNT(*) AS item_count,
        SUM(quantity * unit_price) AS total_purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    customer_id,
    item_count,
    ROUND(total_purchase_amount, 2) AS total_purchase_amount
FROM customer_totals
WHERE total_purchase_amount >= 1000
ORDER BY customer_totals.total_purchase_amount DESC, customer_id ASC;
```

### 실제 실행 결과 — 공유된 결과 중 상위 10행

| customer_id | item_count | total_purchase_amount |
| --- | --- | --- |
| 14646 | 2076 | 280206.02 |
| 18102 | 431 | 259657.30 |
| 17450 | 337 | 194550.79 |
| 16446 | 3 | 168472.50 |
| 14911 | 5675 | 143825.06 |
| 12415 | 714 | 124914.53 |
| 14156 | 1400 | 117379.63 |
| 17511 | 963 | 91062.38 |
| 16029 | 242 | 81024.84 |
| 12346 | 1 | 77183.60 |

실행 성공 결과의 일부입니다. 전체 결과 행 수와 실행 시간은 공유되지 않았습니다.

### 핵심 개념과 결과 해석

COUNT(quantity \* unit_price)도 현재 데이터에서는 COUNT(<i>)와 같은 행 수를 계산합니다. 수량·단가가 모두 NOT NULL이기 때문입니다. 구매 내역 행 수라는 뜻을 직접 나타내는 표현은 COUNT(</i>)입니다. 계산식을 COUNT 안에 넣어도 금액을 더하는 것은 아닙니다.

출력 별칭과 CTE 컬럼 이름이 같으므로 ORDER BY customer_[totals.total](http://totals.total)_purchase_amount로 원래 금액을 지정합니다. ROUND는 표시값에만 적용합니다.
</details>

<details>
<summary>🏁 문제 4 — 윈도우 함수로 전체 고객 구매금액 순위</summary>

## 문제 4. 고객별 누적 구매금액 순위

### 테이블 설명

sales_items의 한 행은 청구서에 기록된 상품 내역 한 줄입니다. 한 줄에서 여러 개를 구매할 수 있고, 한 청구서에 여러 줄이 있을 수 있습니다. 수량과 단가가 양수이고 취소 청구서가 아닌 기록만 포함하는 조회용 뷰입니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| country | VARCHAR(100) | 해당 구매 기록의 국가, NULL 없음 |
| quantity | INT | 구매 수량, NULL 없음 |
| unit_price | DECIMAL(16,6) | 상품 한 개의 단가, GBP, NULL 없음 |

한 줄의 구매금액은 quantity × unit_price입니다. 행 수는 상품 수량 합계나 서로 다른 청구서 수와 다릅니다.

### 문제와 조건

고객별 누적 구매금액을 구하고 전체 고객 중 구매금액 순위를 매깁니다.

- sales_items만 사용하고 고객 ID가 NULL인 기록은 제외합니다.
- 전체 기간을 고객별로 집계하며 CTE 이름은 customer_totals입니다.
- 구매 내역 행 수와 누적 구매금액을 구합니다.
- 1,000 이상 조건 없이 식별 가능한 모든 고객을 포함합니다.
- RANK로 반올림 전 누적 구매금액 내림차순의 순위를 매깁니다.
- 같은 금액은 공동 순위이며 다음 순위를 건너뜁니다.
- 금액은 최종 출력에서 소수 둘째 자리까지 반올림합니다.
- 최종 순위 오름차순, 공동 순위면 고객 ID 오름차순으로 출력합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| purchase_rank | 전체 고객 구매금액 순위 |
| customer_id | 고객 ID |
| item_count | 구매 내역 행 수 |
| total_purchase_amount | 누적 구매금액, GBP |

결과 한 행은 고객 한 명의 통계와 전체 순위입니다.

### 가상 예시와 해설

A 2,500 GBP, B·C 각 1,200 GBP, D 900 GBP이면 순위는 1·2·2·4입니다. 공동 순위는 반올림 전 금액이 같을 때 적용합니다.

### 최종 쿼리

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        COUNT(*) AS item_count,
        SUM(quantity * unit_price) AS total_purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    RANK() OVER (ORDER BY total_purchase_amount DESC) AS purchase_rank,
    customer_id,
    item_count,
    ROUND(total_purchase_amount, 2) AS total_purchase_amount
FROM customer_totals
ORDER BY customer_totals.total_purchase_amount DESC, customer_id ASC;
```

### 실제 실행 결과 — 공유된 결과 중 상위 10행

| purchase_rank | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| 1 | 14646 | 2076 | 280206.02 |
| 2 | 18102 | 431 | 259657.30 |
| 3 | 17450 | 337 | 194550.79 |
| 4 | 16446 | 3 | 168472.50 |
| 5 | 14911 | 5675 | 143825.06 |
| 6 | 12415 | 714 | 124914.53 |
| 7 | 14156 | 1400 | 117379.63 |
| 8 | 17511 | 963 | 91062.38 |
| 9 | 16029 | 242 | 81024.84 |
| 10 | 12346 | 1 | 77183.60 |

실행 성공 결과의 일부입니다. 전체 결과 행 수와 실행 시간은 공유되지 않았습니다.

### 핵심 개념과 결과 해석

OVER 안 ORDER BY는 순위 계산 기준입니다. 여기서는 반올림 전 구매금액을 사용합니다. 고객 ID를 순위 계산에 넣으면 금액이 같은 고객도 별도 순위가 될 수 있으므로 금액만 비교합니다.

마지막 ORDER BY는 출력 순서입니다. 원래 구매금액 내림차순은 이 문제의 purchase_rank 오름차순과 같은 순서를 보장하므로 제출한 정렬도 조건에 맞습니다. 금액이 같으면 고객 ID로 정렬합니다.
</details>

<details>
<summary>🏁 문제 5 — 윈도우 함수로 국가별 고객 구매금액 순위</summary>

## 문제 5. 국가별 고객 구매금액 순위

### 테이블 설명

sales_items의 한 행은 청구서에 기록된 상품 내역 한 줄입니다. 한 줄에서 여러 개를 구매할 수 있고, 한 청구서에 여러 줄이 있을 수 있습니다. 수량과 단가가 양수이고 취소 청구서가 아닌 기록만 포함하는 조회용 뷰입니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| country | VARCHAR(100) | 해당 구매 기록의 국가, NULL 없음 |
| quantity | INT | 구매 수량, NULL 없음 |
| unit_price | DECIMAL(16,6) | 상품 한 개의 단가, GBP, NULL 없음 |

한 줄의 구매금액은 quantity × unit_price입니다. 행 수는 상품 수량 합계나 서로 다른 청구서 수와 다릅니다.

### 문제와 조건

국가·고객별 구매금액을 합산하고 각 국가 안에서 구매금액 순위를 매깁니다.

- sales_items만 사용하고 고객 ID가 NULL인 기록을 제외합니다.
- 전체 기간에 대해 국가와 고객 ID의 조합별로 집계합니다.
- 같은 고객 ID가 여러 국가에 있으면 국가별로 따로 집계합니다.
- CTE 이름은 country_customer_totals입니다.
- 구매 내역 행 수와 누적 구매금액을 구하며 최소 구매금액 조건은 없습니다.
- RANK로 각 국가 안에서 반올림 전 금액 내림차순의 순위를 매깁니다.
- 같은 금액은 공동 순위이고 다음 순위를 건너뜁니다.
- 출력 금액만 소수 둘째 자리까지 반올림합니다.
- 국가 → 국가 내 순위 → 고객 ID 오름차순으로 출력합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| country_rank | 해당 국가 안에서의 구매금액 순위 |
| customer_id | 고객 ID |
| item_count | 해당 국가·고객의 구매 내역 행 수 |
| total_purchase_amount | 해당 국가·고객 누적 구매금액, GBP |

결과 한 행은 특정 국가에서 특정 고객의 구매 통계와 그 국가 안에서의 순위입니다.

### 가상 예시와 해설

France의 A·B가 1·2위이고 Germany의 C·D가 1·2위이면 국가가 바뀔 때 순위가 다시 시작합니다. 이는 고객의 고정된 거주국을 추정한 것이 아니라 구매 기록의 country를 기준으로 나눈 결과입니다.

### 최종 쿼리

```sql
WITH country_customer_totals AS (
    SELECT
        country,
        customer_id,
        COUNT(*) AS item_count,
        SUM(quantity * unit_price) AS total_purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
)
SELECT
    country,
    RANK() OVER (
        PARTITION BY country
        ORDER BY total_purchase_amount DESC
    ) AS country_rank,
    customer_id,
    item_count,
    ROUND(total_purchase_amount, 2) AS total_purchase_amount
FROM country_customer_totals
ORDER BY country ASC, country_rank ASC, customer_id ASC;
```

### 실제 실행 결과 — 공유된 결과 중 일부

| country | country_rank | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- | --- |
| Australia | 1 | 12415 | 714 | 124914.53 |
| Australia | 2 | 12431 | 181 | 5514.67 |
| Australia | 3 | 12388 | 100 | 2780.66 |
| Australia | 4 | 12424 | 30 | 1760.96 |
| Australia | 5 | 12393 | 64 | 1582.60 |
| Australia | 6 | 12434 | 50 | 806.14 |
| Australia | 7 | 12386 | 10 | 401.90 |
| Australia | 8 | 12422 | 21 | 386.20 |
| Australia | 9 | 16321 | 12 | 373.65 |
| Austria | 1 | 12360 | 129 | 2662.06 |
| Austria | 2 | 12865 | 95 | 1568.23 |
| Austria | 3 | 12818 | 14 | 1542.08 |

실행 성공 결과의 일부입니다. 전체 결과 행 수와 실행 시간은 공유되지 않았습니다.

### 핵심 개념과 결과 해석

GROUP BY country, customer_id는 여러 구매 행을 국가·고객별 한 행으로 합칩니다. PARTITION BY country는 그 행을 유지하면서 국가 안에서 순위를 계산합니다. 두 구문의 역할은 다릅니다.

Australia의 1위부터 9위 다음에 Austria의 1위가 나타납니다. 마지막 ORDER BY의 country ASC는 국가 표시 순서를 정하며 순위 계산 자체를 바꾸지 않습니다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — COUNT·NULL·CTE·순위·반올림</summary>

## COUNT(\*)와 COUNT(표현식)

COUNT(\*)는 행을 셉니다. 행의 일부 컬럼이 NULL이어도 포함합니다. COUNT(컬럼 또는 계산식)는 해당 값이 NULL이 아닌 행을 셉니다. 0은 NULL이 아니므로 COUNT에 포함됩니다.

WHERE customer_id IS NOT NULL은 고객 ID가 없는 행만 제거합니다. 다른 컬럼의 NULL 여부까지 보장하지는 않습니다. 현재 sales_items에서는 quantity와 unit_price가 별도로 NOT NULL이므로 COUNT(quantity \* unit_price)도 행 수와 같습니다.

가상 예시: 수량이 3, NULL, 0인 세 행에서 COUNT(\*)는 3, COUNT(quantity)는 2, SUM(quantity)는 3입니다. NULL은 값을 모른다는 뜻이고 0은 값이 0임을 안다는 뜻입니다.

## CTE 안과 바깥

CTE는 쿼리 안에서 이름을 붙인 조회 결과입니다. 고객별 집계를 만들면 한 행은 고객 한 명입니다. 바깥에서는 그 결과를 조회하거나 WHERE로 필터링하고 순위를 붙입니다. 같은 기준의 GROUP BY를 반복할 필요는 없습니다.

## GROUP BY와 PARTITION BY

GROUP BY는 구매 내역 여러 행을 고객별 또는 국가·고객별 한 행으로 줄입니다. PARTITION BY는 집계된 행을 유지하면서 국가마다 순위 계산 범위를 나눕니다.

## 두 ORDER BY의 역할

RANK의 OVER 안 ORDER BY는 순위 계산 기준입니다. 마지막 ORDER BY는 화면에 표시하는 순서입니다. 공동 순위를 유지하려면 순위 계산에 고객 ID를 추가하지 않고 출력 동률 순서에서 사용합니다.

## 반올림과 원래 값

ROUND(total_purchase_amount, 2) AS total_purchase_amount는 표시용 값입니다. 마지막 ORDER BY에서 같은 별칭을 쓰면 반올림된 표시값이 정렬 기준이 됩니다. CTE 이름으로 컬럼을 한정하면 원래 값을 지정할 수 있습니다.

가상 예시: A가 1000.001, B가 1000.004이면 둘 다 1000.00으로 표시되지만 원래 금액은 B가 더 큽니다. 순위·필터·금액 정렬은 원래 값을 사용하고 마지막 표시만 반올림합니다.
</details>

<details>
<summary>🧠 실행 결과 요약·다음 복습</summary>

| 문제 | 내용 | 확인 범위 |
| --- | --- | --- |
| 1 | 오스틴 팀별 집계 | 11행, 0.07초 |
| 2 | 19경기 누적 100점 이상 드라이버 | 8행, 0.00초 |
| 3 | 구매금액 1,000 이상 고객 | 실행 결과 일부 공유 |
| 4 | 전체 고객 구매금액 순위 | 실행 결과 일부 공유 |
| 5 | 국가별 고객 구매금액 순위 | 실행 결과 일부 공유 |

### 다음 복습 — 미실행

- [ ] COUNT(\*)와 COUNT(계산식)의 차이를 NULL 예시로 설명하기
- [ ] CTE 안의 한 행이 무엇인지 설명하기
- [ ] 전체 순위와 국가별 순위를 각각 작성하기
- [ ] 반올림 전 금액으로 순위·정렬을 하고 표시값만 반올림하기
- [ ] JOIN의 두 식별자가 서로 다른 테이블을 가리키는지 확인하기
</details>
</details>
