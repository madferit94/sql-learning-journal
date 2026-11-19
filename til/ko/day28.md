# Day 28 — 금융 거래일 간격·장기 간격 비율

[English](../en/day28.md) · [목차](../../README.ko.md) · [SQL](../../sql/day28.sql)

공개 결과표의 고객 ID는 가명으로 바꿨습니다. 같은 고객은 모든 표에서 같은 가명을 사용합니다.

MySQL 8.4 · finance.bank_transactions. 원본 한 행은 거래 한 건입니다. customer_id는 VARCHAR(20), transaction_date는 DATE이며 두 컬럼 모두 NULL이 아닙니다. 같은 고객이 같은 날 거래한 여러 행은 거래일 하나로 봅니다.

터미널에서는 아래 명령으로 접속합니다.

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

mysql>에서 데이터베이스를 선택합니다.

```sql
USE finance;
```

## 문제 1 — 고객별 거래 간격

고객·거래일당 한 행에 현재 거래일, 같은 고객의 직전 거래일, 그 사이의 일수를 표시하세요. 첫 거래일에는 직전 날짜와 일수를 NULL로 둡니다. 고객 ID·거래일 오름차순으로 처음 20행을 표시합니다. 가상 예: 8월 3일 다음 거래가 8월 7일이면 간격은 4일입니다.

```sql
WITH customer_dates AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
)
SELECT customer_id, transaction_date,
       LAG(transaction_date) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       ) AS previous_transaction_date,
       DATEDIFF(transaction_date, LAG(transaction_date) OVER (
           PARTITION BY customer_id ORDER BY transaction_date
       )) AS days_since_previous
FROM customer_dates
ORDER BY customer_id ASC, transaction_date ASC
LIMIT 20;
```

실제 실행 20행 중 일부:

| customer_id | transaction_date | previous_transaction_date | days_since_previous |
| --- | --- | --- | --- |
| customer_01 | 2016-08-09 | NULL | NULL |
| customer_01 | 2016-09-26 | 2016-08-09 | 48 |
| customer_02 | 2016-08-14 | NULL | NULL |

LAG는 앞 행의 날짜를 가져오고 DATEDIFF는 두 날짜의 달력상 일수 차이를 구합니다. 날짜에 단순 빼기를 적용하는 것과 다릅니다.

## 문제 2 — 고객별 평균 거래 간격

서로 다른 거래일이 3일 이상인 고객마다 거래일 수와 평균 거래 간격을 구하세요. 첫 거래일은 거래일 수에는 넣고 평균에서는 제외합니다. 전체 데이터로 계산하고, 반올림 전 평균 내림차순·고객 ID 오름차순으로 처음 20행을 표시합니다. 평균은 출력할 때만 둘째 자리까지 반올림합니다. 가상 예: 간격이 NULL, 4, 9라면 거래일은 3일이고 평균은 6.50일입니다.

```sql
WITH active_day AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_days AS (
    SELECT customer_id,
           DATEDIFF(transaction_date, LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           )) AS days_since_previous
    FROM active_day
)
SELECT customer_id, COUNT(*) AS active_day_count,
       ROUND(AVG(days_since_previous), 2) AS avg_days_between_transactions
FROM prev_days
GROUP BY customer_id
HAVING active_day_count >= 3
ORDER BY AVG(days_since_previous) DESC, customer_id
LIMIT 20;
```

실제 실행 20행 중 일부:

| customer_id | active_day_count | avg_days_between_transactions |
| --- | --- | --- |
| customer_04 | 3 | 40.50 |
| customer_07 | 3 | 40.50 |
| customer_06 | 3 | 40.00 |

고객·거래일당 한 행으로 간격을 계산한 후 고객당 한 행으로 다시 집계합니다. COUNT(*)에는 첫날이 포함되지만 AVG는 NULL인 첫날을 건너뜁니다.

## 문제 3 — 30일 이상 지나 다시 거래한 기록

같은 고객의 직전 거래일부터 30일 이상 지난 거래일을 찾으세요. 정확히 30일도 포함합니다. 간격 내림차순·고객 ID 오름차순·거래일 오름차순으로 처음 20행을 표시합니다. 가상 예: 직전 거래가 8월 5일이고 이번 거래가 9월 4일이면 30일이므로 포함합니다.

```sql
WITH active_day AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_days AS (
    SELECT customer_id, transaction_date,
           LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           ) AS previous_transaction_date
    FROM active_day
)
SELECT customer_id, transaction_date, previous_transaction_date,
       DATEDIFF(transaction_date, previous_transaction_date) AS days_since_previous
FROM prev_days
WHERE DATEDIFF(transaction_date, previous_transaction_date) >= 30
ORDER BY days_since_previous DESC, customer_id ASC, transaction_date ASC
LIMIT 20;
```

실제 실행 20행 중 일부:

| customer_id | transaction_date | previous_transaction_date | days_since_previous |
| --- | --- | --- | --- |
| customer_03 | 2016-10-21 | 2016-08-01 | 81 |
| customer_09 | 2016-10-21 | 2016-08-01 | 81 |
| customer_11 | 2016-10-21 | 2016-08-02 | 80 |

마지막 WHERE는 해당 거래일 행을 남깁니다. 고객별 GROUP BY를 추가하면 이번 문제에서 필요한 거래일별 행을 유지하지 못합니다. 중복 제거 단계에서는 고객과 거래일을 함께 GROUP BY해도 됩니다.

## 문제 4 — 30일 이상 간격이 두 번 이상인 고객

직전 거래일과 30일 이상 떨어진 간격이 두 번 이상인 고객마다 해당 간격 수와 최댓값을 구하세요. 해당 간격 수 내림차순·최대 간격 내림차순·고객 ID 오름차순으로 처음 20행을 표시합니다. 가상 예: 간격이 NULL, 30, 9, 41이면 2회이고 최대는 41일입니다.

```sql
WITH active_customer AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM bank_transactions
),
prev_day AS (
    SELECT customer_id, transaction_date,
           DATEDIFF(transaction_date, LAG(transaction_date) OVER (
               PARTITION BY customer_id ORDER BY transaction_date
           )) AS previous_date
    FROM active_customer
)
SELECT customer_id, COUNT(previous_date) AS long_gap_count,
       MAX(previous_date) AS longest_gap_days
FROM prev_day
WHERE previous_date >= 30
GROUP BY customer_id
HAVING long_gap_count >= 2
ORDER BY long_gap_count DESC, longest_gap_days DESC, customer_id ASC
LIMIT 20;
```

실제 실행 20행 중 일부:

| customer_id | long_gap_count | longest_gap_days |
| --- | --- | --- |
| customer_20 | 2 | 50 |
| customer_15 | 2 | 48 |
| customer_28 | 2 | 47 |

WHERE는 어떤 간격 행을 셀지 정하고, HAVING은 집계한 뒤 어떤 고객을 남길지 정합니다. 제출 SQL의 previous_date에는 날짜가 아닌 간격 일수가 들어갑니다.

## 문제 5 — 다시 거래할 때 30일 이상 기다린 비중

고객 한 명의 거래 기록을 날짜순으로 살펴봅니다. 첫 거래일에는 앞선 날짜가 없으므로 건너뜁니다. 그다음 거래일부터는 직전 거래일에서 며칠이 지났는지 하나씩 셉니다. 이렇게 비교할 수 있었던 간격 전체 중에서, 30일 이상이었던 간격의 비율을 고객별로 구하세요.

- 서로 다른 날에 3일 이상 거래한 고객만 봅니다. 같은 날 여러 번 거래해도 하루로 계산합니다.
- 30일 미만인 간격도 전체 간격 수에는 포함합니다. 정확히 30일은 긴 간격으로 셉니다.
- 긴 간격이 하나도 없어도 대상 고객이라면 표시하며 비율은 0.00입니다.
- 전체 데이터로 계산합니다. 반올림 전 비율 내림차순 → 긴 간격 수 내림차순 → 고객 ID 오름차순으로 정렬한 뒤 처음 20행을 표시합니다. 비율은 출력할 때만 소수 둘째 자리까지 반올림합니다.

| 출력 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| total_gap_count | 첫날을 제외하고, 직전 거래일과 비교할 수 있었던 간격의 수 |
| long_gap_count | 전체 간격 중 30일 이상인 간격의 수 |
| long_gap_rate | 긴 간격 수 ÷ 전체 간격 수 × 100 |

가상 예: 간격이 NULL, 30일, 9일, 41일이라면 전체 간격은 3개입니다. 그중 30일과 41일, 두 개가 조건을 충족하므로 비율은 2 ÷ 3 × 100 = 66.67%입니다. 9일도 분모에는 들어갑니다.

### NULLIF의 뜻과 쓰는 이유

NULLIF(a, b)는 a와 b가 같으면 NULL을, 다르면 a를 반환합니다. NULLIF(total_gap_count, 0)은 간격이 0개일 때만 분모를 NULL로 바꿔 0으로 나누지 않게 합니다. 비교할 간격이 없어 계산할 수 없는 비율(NULL)과, 간격은 있지만 긴 간격이 하나도 없는 비율(0.00%)을 구분할 수 있습니다.

이번에는 거래일이 3일 이상이라 모든 대상 고객의 간격이 최소 2개입니다. 따라서 NULLIF가 없어도 안전하고 두 풀이가 같은 결과를 냅니다. 거래일 하루인 고객도 포함하도록 조건을 바꾸면 NULLIF가 의미를 갖습니다.

표시할 때 쓰는 ROUND와 정렬은 분리합니다. 정렬에도 ROUND를 쓰면 서로 다른 비율이 동률이 될 수 있습니다.

## 사례 5-1 — NULLIF 사용

```sql
WITH customer_date AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM finance.bank_transactions
),
prev_day AS (
    SELECT
        customer_id,
        transaction_date,
        LAG(transaction_date) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_date
    FROM customer_date
),
gap_count AS (
    SELECT
        customer_id,
        COUNT(previous_date) AS total_gap_count,
        COUNT(
            CASE WHEN DATEDIFF(transaction_date, previous_date) >= 30
                 THEN 1
            END
        ) AS long_gap_count
    FROM prev_day
    GROUP BY customer_id
    HAVING COUNT(*) >= 3
)
SELECT
    customer_id,
    total_gap_count,
    long_gap_count,
    ROUND(long_gap_count / NULLIF(total_gap_count, 0) * 100, 2) AS long_gap_rate
FROM gap_count
ORDER BY long_gap_count / NULLIF(total_gap_count, 0) DESC,
         long_gap_count DESC,
         customer_id ASC
LIMIT 20;
```

사용자 실행: 20행 (31.11 sec).

## 사례 5-2 — NULLIF 미사용

```sql
WITH customer_date AS (
    SELECT DISTINCT customer_id, transaction_date
    FROM finance.bank_transactions
),
prev_day AS (
    SELECT
        customer_id,
        transaction_date,
        LAG(transaction_date) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_date
    FROM customer_date
),
gap_count AS (
    SELECT
        customer_id,
        COUNT(previous_date) AS total_gap_count,
        COUNT(
            CASE WHEN DATEDIFF(transaction_date, previous_date) >= 30
                 THEN 1
            END
        ) AS long_gap_count
    FROM prev_day
    GROUP BY customer_id
    HAVING COUNT(*) >= 3
)
SELECT
    customer_id,
    total_gap_count,
    long_gap_count,
    ROUND(long_gap_count / total_gap_count * 100, 2) AS long_gap_rate
FROM gap_count
ORDER BY long_gap_count / total_gap_count DESC,
         long_gap_count DESC,
         customer_id ASC
LIMIT 20;
```

사용자 실행: 20행 (15.81 sec).

### 두 풀이의 실제 공통 결과

두 결과표는 순서까지 20행 모두 같습니다. 단일 실행 시간만으로 두 방식의 성능 차이는 판단하지 않습니다.

| customer_id | total_gap_count | long_gap_count | long_gap_rate |
| --- | --- | --- | --- |
| customer_05 | 2 | 2 | 100.00 |
| customer_06 | 2 | 2 | 100.00 |
| customer_08 | 2 | 2 | 100.00 |
| customer_10 | 2 | 2 | 100.00 |
| customer_12 | 2 | 2 | 100.00 |
| customer_13 | 2 | 2 | 100.00 |
| customer_14 | 2 | 2 | 100.00 |
| customer_15 | 2 | 2 | 100.00 |
| customer_16 | 2 | 2 | 100.00 |
| customer_17 | 2 | 2 | 100.00 |
| customer_18 | 2 | 2 | 100.00 |
| customer_19 | 2 | 2 | 100.00 |
| customer_20 | 2 | 2 | 100.00 |
| customer_21 | 2 | 2 | 100.00 |
| customer_22 | 2 | 2 | 100.00 |
| customer_23 | 2 | 2 | 100.00 |
| customer_24 | 2 | 2 | 100.00 |
| customer_25 | 2 | 2 | 100.00 |
| customer_26 | 2 | 2 | 100.00 |
| customer_27 | 2 | 2 | 100.00 |

## 이해 점검·복습

- 거래일이 3일이면 간격은 왜 2개인지 설명하기.
- 3번은 거래일별 필터, 4번은 조건을 충족한 거래일을 고객별로 집계, 5번은 전체 간격을 유지한 채 조건부로 세는 차이 복습하기.
- 고객별 평균 간격을 구할 때 거래일·간격·고객 단위를 순서대로 적고 다시 작성하기.
