# Day 27 — 금융 월별 증감·고객별 직전 거래일 비교

[English](../en/day27.md) · [목차](../../README.ko.md) · [SQL](../../sql/day27.sql)

MySQL / finance. bank_transactions의 한 행은 거래 한 건입니다. 이번 문제에서 쓰는 세 컬럼은 모두 NULL을 허용하지 않습니다. 출력의 NULL은 비교할 앞 행이 없거나 증감률을 정의할 수 없는 경우입니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| customer_id | VARCHAR(20) | 고객 ID |
| transaction_date | DATE | 거래일 |
| transaction_amount | DECIMAL(15,2) | 거래 금액(원본 단위) |

터미널에서 접속하고 mysql>에서 데이터베이스를 선택합니다.

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

```sql
USE finance;
```

공개 결과표의 고객 ID는 가명입니다. 같은 고객은 모든 표에서 같은 가명을 사용합니다.

## 문제 1 — 월별 거래 건수와 거래 고객 수

거래가 있었던 월을 YYYY-MM으로 표시합니다. 거래 건수는 모든 거래 행, 고객 수는 월 안에서 서로 다른 고객 ID 수, 총액은 모든 거래 금액의 합계입니다. 거래 월 오름차순으로 월당 한 행을 출력합니다. 가상 예: A가 100과 200, B가 300을 거래하면 3건·2명·600.00입니다.

### 최종 기록 SQL

```sql
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       COUNT(*) AS transaction_count,
       COUNT(DISTINCT customer_id) AS customer_count,
       SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month;
```

### 실제 실행 결과

| transaction_month | transaction_count | customer_count | total_transaction_amount |
| --- | --- | --- | --- |
| 2016-08 | 653933 | 586592 | 1030599493.84 |
| 2016-09 | 390975 | 366148 | 612531219.10 |
| 2016-10 | 3659 | 3654 | 7665018.63 |

## 문제 2 — 월별 총 거래 금액의 전월 대비 차이

월별 합계와 직전 월 합계, 이번 달에서 직전 월을 뺀 차이를 출력합니다. 첫 달의 비교 값과 차이는 NULL입니다. 월 오름차순입니다. 가상 예: 600 → 450이면 차이는 -150.00입니다. LAG는 달력상 전월이 아니라 정렬상 앞 행을 읽습니다. 이 데이터의 관측 월은 연속입니다.

### 최종 기록 SQL

```sql
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       SUM(transaction_amount) AS total_transaction_amount,
       LAG(SUM(transaction_amount)) OVER (
           ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')
       ) AS previous_month_amount,
       SUM(transaction_amount) - LAG(SUM(transaction_amount)) OVER (
           ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')
       ) AS amount_change
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month;
```

### 실제 실행 결과

| transaction_month | total_transaction_amount | previous_month_amount | amount_change |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | NULL | NULL |
| 2016-09 | 612531219.10 | 1030599493.84 | -418068274.74 |
| 2016-10 | 7665018.63 | 612531219.10 | -604866200.47 |

## 문제 3-1 — 기본 정답: 두 CTE와 NULLIF

월별 총액과 전월 총액, (이번 달 − 전월) ÷ 전월 × 100을 출력합니다. 비율만 소수 둘째 자리로 반올림하고 월 오름차순으로 정렬합니다. 첫 달 또는 분모가 0이면 비율은 NULL입니다. 가상 예: 600 → 450이면 -25.00%입니다.

월별 합계와 전월 금액을 순서대로 준비합니다. 첫 CTE에서 월별 한 행이 이미 만들어져 바깥 GROUP BY는 필요 없습니다. NULLIF는 분모가 0이면 NULL로 바꿉니다.

### 최종 기록 SQL

```sql
WITH month_amount AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
           SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY transaction_month
),
lag_amount AS (
    SELECT transaction_month, total_transaction_amount,
           LAG(total_transaction_amount) OVER (
               ORDER BY transaction_month
           ) AS previous_month_amount
    FROM month_amount
)
SELECT transaction_month, total_transaction_amount, previous_month_amount,
       ROUND((total_transaction_amount - previous_month_amount)
             / NULLIF(previous_month_amount, 0) * 100, 2) AS amount_change_rate
FROM lag_amount
ORDER BY transaction_month;
```

### 실제 실행 결과

| transaction_month | total_transaction_amount | previous_month_amount | amount_change_rate |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | NULL | NULL |
| 2016-09 | 612531219.10 | 1030599493.84 | -40.57 |
| 2016-10 | 7665018.63 | 612531219.10 | -98.75 |

## 문제 3-2 — 대안: CTE 없이 이름 있는 WINDOW

월별 총액과 전월 총액, (이번 달 − 전월) ÷ 전월 × 100을 출력합니다. 비율만 소수 둘째 자리로 반올림하고 월 오름차순으로 정렬합니다. 첫 달 또는 분모가 0이면 비율은 NULL입니다. 가상 예: 600 → 450이면 -25.00%입니다.

WINDOW month_order AS (ORDER BY MIN(transaction_date))는 윈도우의 정렬 규칙에 이름을 붙입니다. 각 월의 첫 거래일을 기준으로 정렬하며, OVER month_order에서 그 규칙을 재사용합니다. LAG의 계산 결과에 별칭을 붙여 재사용하는 문법은 아닙니다. 마지막 ORDER BY는 결과표 표시 순서입니다. 기본 정답과 실제 결과가 3행 모두 같습니다.

### 최종 기록 SQL

```sql
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
       SUM(transaction_amount) AS total_transaction_amount,
       LAG(SUM(transaction_amount)) OVER month_order AS previous_month_amount,
       ROUND(
           (SUM(transaction_amount) - LAG(SUM(transaction_amount)) OVER month_order)
           / NULLIF(LAG(SUM(transaction_amount)) OVER month_order, 0) * 100,
           2
       ) AS amount_change_rate
FROM finance.bank_transactions
GROUP BY transaction_month
WINDOW month_order AS (ORDER BY MIN(transaction_date))
ORDER BY transaction_month;
```

### 실제 실행 결과

| transaction_month | total_transaction_amount | previous_month_amount | amount_change_rate |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | NULL | NULL |
| 2016-09 | 612531219.10 | 1030599493.84 | -40.57 |
| 2016-10 | 7665018.63 | 612531219.10 | -98.75 |

## 문제 3-3 — 표시 변형: IFNULL로 0.00 표기

월별 총액과 전월 총액, (이번 달 − 전월) ÷ 전월 × 100을 출력합니다. 비율만 소수 둘째 자리로 반올림하고 월 오름차순으로 정렬합니다. 첫 달 또는 분모가 0이면 비율은 NULL입니다. 가상 예: 600 → 450이면 -25.00%입니다.

계산에는 원본 전월 값과 NULLIF 분모를 유지합니다. 최종 SELECT에서 전월 금액과 증감률을 따로 IFNULL로 감싸 표시만 바꿉니다. 계산 불가와 실제 0%가 같은 모양이 되므로 원래 문제의 정답과 구분합니다. 아래 표는 별도 실행으로 확인한 결과입니다.

### 최종 기록 SQL

```sql
WITH month_amount AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
           SUM(transaction_amount) AS total_transaction_amount
    FROM finance.bank_transactions
    GROUP BY transaction_month
),
lag_amount AS (
    SELECT transaction_month, total_transaction_amount,
           LAG(total_transaction_amount) OVER (
               ORDER BY transaction_month
           ) AS previous_month_amount
    FROM month_amount
)
SELECT transaction_month, total_transaction_amount,
       IFNULL(previous_month_amount, 0.00) AS previous_month_amount,
       IFNULL(ROUND((total_transaction_amount - previous_month_amount)
                    / NULLIF(previous_month_amount, 0) * 100, 2), 0.00) AS amount_change_rate
FROM lag_amount
ORDER BY transaction_month;
```

### 별도 실행 확인

| transaction_month | total_transaction_amount | previous_month_amount | amount_change_rate |
| --- | --- | --- | --- |
| 2016-08 | 1030599493.84 | 0.00 | 0.00 |
| 2016-09 | 612531219.10 | 1030599493.84 | -40.57 |
| 2016-10 | 7665018.63 | 612531219.10 | -98.75 |

## 문제 4-1 — 제출 풀이: DATE_FORMAT 사용

한 고객의 같은 날짜 거래를 합산하고, 같은 고객의 그보다 앞선 가장 최근 거래일 합계를 붙입니다. 첫 거래일은 NULL입니다. 고객 ID·거래일 오름차순으로 처음 20행을 출력합니다. 가상 예: A가 8월 3일과 7일에 거래했다면 7일 행의 직전 값은 3일 합계입니다.

20행 결과는 맞았습니다. SHOW WARNINGS에서 1052: Column 'transaction_date' in group statement is ambiguous를 확인했습니다. GROUP BY에 쓴 이름이 원본 컬럼과 DATE_FORMAT의 별칭에 동시에 사용됐습니다.

### 최종 기록 SQL

```sql
WITH customer_daily_amount AS (
    SELECT customer_id,
           DATE_FORMAT(transaction_date, '%Y-%m-%d') AS transaction_date,
           SUM(transaction_amount) AS daily_amount
    FROM bank_transactions
    GROUP BY customer_id, transaction_date
)
SELECT customer_id, transaction_date, daily_amount,
       LAG(daily_amount) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_day_amount
FROM customer_daily_amount
ORDER BY customer_id, transaction_date
LIMIT 20;
```

### 실제 실행 결과

| customer_id | transaction_date | daily_amount | previous_day_amount |
| --- | --- | --- | --- |
| customer_01 | 2016-08-09 | 356.00 | NULL |
| customer_01 | 2016-09-26 | 4750.00 | 356.00 |
| customer_02 | 2016-08-14 | 1499.00 | NULL |
| customer_03 | 2016-08-01 | 1205.00 | NULL |
| customer_03 | 2016-08-07 | 250.00 | 1205.00 |
| customer_04 | 2016-09-15 | 30.00 | NULL |
| customer_05 | 2016-08-18 | 5000.00 | NULL |
| customer_06 | 2016-08-29 | 557.00 | NULL |
| customer_07 | 2016-08-03 | 404.00 | NULL |
| customer_07 | 2016-08-04 | 1460.00 | 404.00 |
| customer_08 | 2016-08-01 | 50.00 | NULL |
| customer_08 | 2016-08-27 | 700.00 | 50.00 |
| customer_09 | 2016-08-26 | 208.00 | NULL |
| customer_10 | 2016-08-09 | 19680.00 | NULL |
| customer_11 | 2016-09-07 | 100.00 | NULL |
| customer_12 | 2016-09-02 | 915.00 | NULL |
| customer_13 | 2016-08-06 | 2397.00 | NULL |
| customer_13 | 2016-09-07 | 20.00 | 2397.00 |
| customer_13 | 2016-09-10 | 14500.00 | 20.00 |
| customer_14 | 2016-08-18 | 201.00 | NULL |

## 문제 4-2 — 대안: 원본 DATE 유지

한 고객의 같은 날짜 거래를 합산하고, 같은 고객의 그보다 앞선 가장 최근 거래일 합계를 붙입니다. 첫 거래일은 NULL입니다. 고객 ID·거래일 오름차순으로 처음 20행을 출력합니다. 가상 예: A가 8월 3일과 7일에 거래했다면 7일 행의 직전 값은 3일 합계입니다.

원본이 이미 DATE이므로 날짜 변환 없이 묶거나 정렬할 수 있습니다. 20행은 제출 풀이와 모두 같았고 대안 실행에는 경고가 없었습니다.

### 최종 기록 SQL

```sql
WITH customer_daily_amount AS (
    SELECT customer_id, transaction_date, SUM(transaction_amount) AS daily_amount
    FROM finance.bank_transactions
    GROUP BY customer_id, transaction_date
)
SELECT customer_id, transaction_date, daily_amount,
       LAG(daily_amount) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_day_amount
FROM customer_daily_amount
ORDER BY customer_id, transaction_date
LIMIT 20;
```

### 실제 실행 결과

| customer_id | transaction_date | daily_amount | previous_day_amount |
| --- | --- | --- | --- |
| customer_01 | 2016-08-09 | 356.00 | NULL |
| customer_01 | 2016-09-26 | 4750.00 | 356.00 |
| customer_02 | 2016-08-14 | 1499.00 | NULL |
| customer_03 | 2016-08-01 | 1205.00 | NULL |
| customer_03 | 2016-08-07 | 250.00 | 1205.00 |
| customer_04 | 2016-09-15 | 30.00 | NULL |
| customer_05 | 2016-08-18 | 5000.00 | NULL |
| customer_06 | 2016-08-29 | 557.00 | NULL |
| customer_07 | 2016-08-03 | 404.00 | NULL |
| customer_07 | 2016-08-04 | 1460.00 | 404.00 |
| customer_08 | 2016-08-01 | 50.00 | NULL |
| customer_08 | 2016-08-27 | 700.00 | 50.00 |
| customer_09 | 2016-08-26 | 208.00 | NULL |
| customer_10 | 2016-08-09 | 19680.00 | NULL |
| customer_11 | 2016-09-07 | 100.00 | NULL |
| customer_12 | 2016-09-02 | 915.00 | NULL |
| customer_13 | 2016-08-06 | 2397.00 | NULL |
| customer_13 | 2016-09-07 | 20.00 | 2397.00 |
| customer_13 | 2016-09-10 | 14500.00 | 20.00 |
| customer_14 | 2016-08-18 | 201.00 | NULL |

## 문제 5 — 거래 금액이 늘어난 날이 2일 이상인 고객

전체 데이터에서 고객·거래일별 합계를 만들고 같은 고객의 직전 거래일보다 합계가 엄격히 늘어난 날을 셉니다. 첫날과 동률인 날은 제외합니다. 증가일이 2일 이상인 고객만 남긴 뒤 증가일 수 내림차순·고객 ID 오름차순으로 처음 20행을 출력합니다. 가상 예: 100 → 150 → 120 → 200이면 2일입니다.

비교식이 참일 때만 세므로 직전 값이 NULL인 첫날과 동률은 세지 않습니다. 원본 결과에서 최댓값은 4일입니다.

### 최종 기록 SQL

```sql
WITH customer_daily_amount AS (
    SELECT customer_id, transaction_date, SUM(transaction_amount) AS daily_amount
    FROM finance.bank_transactions
    GROUP BY customer_id, transaction_date
),
prev_amount AS (
    SELECT customer_id, transaction_date, daily_amount,
           LAG(daily_amount) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           ) AS previous_day_amount
    FROM customer_daily_amount
)
SELECT customer_id,
       COUNT(CASE WHEN previous_day_amount < daily_amount THEN 1 END) AS increase_day_count
FROM prev_amount
GROUP BY customer_id
HAVING increase_day_count >= 2
ORDER BY increase_day_count DESC, customer_id
LIMIT 20;
```

### 실제 실행 결과

| customer_id | increase_day_count |
| --- | --- |
| customer_31 | 4 |
| customer_15 | 3 |
| customer_16 | 3 |
| customer_17 | 3 |
| customer_18 | 3 |
| customer_19 | 3 |
| customer_20 | 3 |
| customer_21 | 3 |
| customer_22 | 3 |
| customer_23 | 3 |
| customer_24 | 3 |
| customer_25 | 3 |
| customer_26 | 3 |
| customer_27 | 3 |
| customer_28 | 3 |
| customer_29 | 3 |
| customer_30 | 3 |
| customer_32 | 3 |
| customer_33 | 3 |
| customer_34 | 3 |

## 이해 점검

월별 집계는 월당 한 행, 고객별 일별 집계는 고객·거래일당 한 행입니다. LAG의 ORDER BY는 앞 행을 정하고, 마지막 ORDER BY는 출력 순서를 정합니다. 거래가 없던 기간은 결과에 없으므로 거래가 기록된 날짜 사이를 비교합니다. 월 경계의 관측량이 다를 수 있으므로 월 합계 하락만으로 고객 행동 변화를 단정하지 않습니다.
