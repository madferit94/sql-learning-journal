# 💳 Day19 — Finance 집계 복습·CTE 기초

[English](../en/day19.md) · [목차](../../README.ko.md) · [검증 기록](../../docs/audit.ko.md)

<details>
<summary>💳 Day19 — Finance 집계 복습·CTE 기초</summary>

# SQL 학습 기록 — Day 19

## 학습 개요

<b>환경:</b> MySQL / finance / bank_transactions
<b>학습 내용:</b> 월별 집계, 조건부 집계, 거래 날짜 중복 제거, 고객별 누적 금액, CTE 기초
<b>진행 범위:</b> 금융 복습 3문제와 CTE 기초 연습 2개. 이어 진행한 학습을 한 세션으로 묶었습니다.
<b>검증 근거:</b> 제출 SQL 검토 및 사용자가 공유한 MySQL 실행 결과

### 접속 방법

일반 터미널에서 MySQL에 접속합니다.

```bash
mysql -u root -p
```

mysql> 화면에서 데이터베이스를 선택합니다. 이미 접속했다면 여기부터 실행합니다.

```sql
USE finance;
```

### 데이터 설명

bank_transactions의 한 행은 거래 한 건이며 같은 고객이 같은 날짜에 여러 번 거래할 수 있습니다.

| 컬럼 | 자료형 | 의미 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer_id | VARCHAR(20) | 고객 ID |
| transaction_date | DATE | 거래 날짜 |
| transaction_amount | DECIMAL(15,2) | 거래금액 |

위 컬럼에는 NULL이 없습니다. 금액 통화는 이번 기록에서 별도로 확정하지 않습니다.

<details>
<summary>📚 문제 1\~3 — 월별 집계·고액 거래·고객 선별</summary>

## 문제 1. 월별 거래 통계

### 테이블 설명

bank_transactions의 한 행은 금융 거래 한 건입니다. 같은 고객이 같은 날 여러 번 거래할 수 있습니다. 아래는 필요한 컬럼 일부이며 NULL이 없습니다.

| 컬럼 | 자료형 | 의미 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer_id | VARCHAR(20) | 고객 ID |
| transaction_date | DATE | 거래 날짜 |
| transaction_amount | DECIMAL(15,2) | 거래금액 |

금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

전체 기간의 거래를 연월별로 집계하여 거래 건수, 총 거래금액, 거래 한 건당 평균 금액을 조회합니다. 결과 한 행은 한 달의 거래 통계입니다.

### 조건

- 거래 연월은 YYYY-MM 형식입니다.
- 모든 거래를 집계하고 거래 기록이 있는 월만 출력합니다.
- 평균은 소수점 둘째 자리까지 반올림합니다.
- 총액은 소수점 둘째 자리까지 표시합니다.
- 거래 연월 오름차순으로 정렬합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| transaction_month | 거래 연월 |
| transaction_count | 전체 거래 건수 |
| total_transaction_amount | 총 거래금액 |
| avg_transaction_amount | 거래 한 건당 평균 금액 |

### 가상 출력 예시

| transaction_month | transaction_count | total_transaction_amount | avg_transaction_amount |
| --- | --- | --- | --- |
| 2016-08 | 4 | 10000.00 | 2500.00 |

거래 4건의 합계가 10000이면 거래 한 건당 평균은 2500입니다. 가상 예시입니다.

### 제출 쿼리

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;
```

### 실제 실행 결과

| transaction_month | transaction_count | total_transaction_amount | avg_transaction_amount |
| --- | --- | --- | --- |
| 2016-08 | 653933 | 1030599493.84 | 1576.00 |
| 2016-09 | 390975 | 612531219.10 | 1566.68 |
| 2016-10 | 3659 | 7665018.63 | 2094.84 |

사용자가 추가로 공유한 MySQL 실행 결과: 3 rows in set (2.38 sec). 실행 시간은 사용자 환경의 기록입니다.

### 검증 및 핵심 개념

<b>첫 제출 쿼리 정답·사용자 실행 결과 확인.</b> 월별 그룹화, 전체 거래 건수, 총 거래금액, 거래 한 건당 평균과 연월 오름차순 정렬을 모두 충족합니다. 이번 보완 과정에서 AI도 로컬 finance DB에서 같은 SELECT를 읽기 전용으로 실행하여, 3개 월의 모든 집계값이 사용자 출력과 일치함을 확인했습니다.

transaction_amount가 소수점 두 자리인 DECIMAL 자료형이므로 합계도 소수점 두 자리로 계산됩니다.

---

## 문제 2. 월별 고액 거래 통계

### 테이블 설명

bank_transactions의 한 행은 금융 거래 한 건입니다. 같은 고객이 같은 날 여러 번 거래할 수 있습니다. 아래는 필요한 컬럼 일부이며 NULL이 없습니다.

| 컬럼 | 자료형 | 의미 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer_id | VARCHAR(20) | 고객 ID |
| transaction_date | DATE | 거래 날짜 |
| transaction_amount | DECIMAL(15,2) | 거래금액 |

금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

연월별 전체 거래 건수, 고액 거래 건수, 고액 거래금액 합계와 고액 거래 비율을 조회합니다. 한 행은 한 달의 통계입니다.

### 조건

- 전체 기간에서 거래금액 5000 이상을 고액 거래로 정의합니다. 정확히 5000도 포함합니다.
- 거래 연월은 YYYY-MM 형식입니다.
- 고액 합계에는 고액 거래금액만 더합니다.
- 고액 비율은 고액 거래 건수 / 전체 거래 건수 × 100입니다.
- 비율은 소수점 둘째 자리까지 반올림합니다.
- 고액 거래가 없는 월도 거래 기록이 있다면 포함하고 고액 건수·합계·비율을 0으로 표시합니다.
- 거래 연월 오름차순으로 정렬합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| transaction_month | 거래 연월 |
| transaction_count | 전체 거래 건수 |
| high_amount_count | 고액 거래 건수 |
| high_amount_total | 고액 거래금액 합계 |
| high_amount_rate | 고액 거래 비율(%) |

### 가상 예시

한 달의 거래금액이 1000, 5000, 7000, 2000이면 다음과 같습니다.

| transaction_month | transaction_count | high_amount_count | high_amount_total | high_amount_rate |
| --- | --- | --- | --- | --- |
| 2016-08 | 4 | 2 | 12000.00 | 50.00 |

5000과 7000 두 건의 합계는 12000이고, 비율은 2 / 4 × 100 = 50%입니다.

### 최종 답안 정리본

비율의 분모는 COUNT(transaction_date)입니다. 날짜에 NULL이 없어 전체 거래 건수와 같습니다.

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    SUM(
        CASE
            WHEN transaction_amount >= 5000 THEN transaction_amount
            ELSE 0
        END
    ) AS high_amount_total,
    ROUND(
        COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(transaction_date) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;
```

### 실제 결과

사용자가 공유한 실행 결과에서 요구된 컬럼만 정리했습니다. 아래 정리본 SQL을 별도로 재실행한 결과라고 주장하지 않습니다.

| transaction_month | transaction_count | high_amount_count | high_amount_total | high_amount_rate |
| --- | --- | --- | --- | --- |
| 2016-08 | 653933 | 35767 | 556043304.17 | 5.47 |
| 2016-09 | 390975 | 21446 | 329052383.08 | 5.49 |
| 2016-10 | 3659 | 246 | 5057837.26 | 6.72 |

### 핵심 개념

- COUNT(\*)는 거래 건수를 셉니다.
- COUNT(DISTINCT transaction_date)는 서로 다른 거래 날짜 수를 셉니다.
- 조건부 금액 합계는 조건을 만족하면 거래금액을, 아니면 0을 반환하여 더합니다.
- 날짜에 NULL이 없으므로 이번 분모의 COUNT(transaction_date)와 COUNT(\*)는 같습니다.
실제 출력에는 고액 0건인 월이 없어 해당 경우를 실제 결과로 검증했다고 기록하지 않습니다.

---

## 문제 3. 거래일 수와 누적 금액 조건을 만족하는 고객

### 테이블 설명

bank_transactions의 한 행은 금융 거래 한 건입니다. 같은 고객이 같은 날 여러 번 거래할 수 있습니다. 아래는 필요한 컬럼 일부이며 NULL이 없습니다.

| 컬럼 | 자료형 | 의미 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer_id | VARCHAR(20) | 고객 ID |
| transaction_date | DATE | 거래 날짜 |
| transaction_amount | DECIMAL(15,2) | 거래금액 |

금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

전체 기간에서 서로 다른 3일 이상 거래했고, 누적 거래금액이 10000 이상인 고객을 조회합니다.

### 조건

- 같은 날 여러 번 거래해도 날짜 수는 1일입니다. 거래 날짜는 연속일 필요가 없습니다.
- 거래 건수와 누적 금액에는 해당 고객의 모든 거래를 포함합니다.
- 정확히 3일, 정확히 10000도 포함합니다.
- 거래 날짜 수 내림차순 → 누적 금액 내림차순 → 고객 ID 오름차순으로 정렬합니다.

### 출력 컬럼

결과 한 행은 조건을 만족한 고객 한 명입니다.

| 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| transaction_count | 전체 거래 건수 |
| active_day_count | 서로 다른 거래 날짜 수 |
| total_transaction_amount | 누적 거래금액 |

### 가상 예시

한 고객이 서로 다른 3일에 4000씩 거래했다면 다음처럼 포함됩니다.

| customer_id | transaction_count | active_day_count | total_transaction_amount |
| --- | --- | --- | --- |
| CUSTOMER_A | 3 | 3 | 12000.00 |

### 첫 시도에서 수정한 부분

1. 전체 거래 건수와 서로 다른 날짜 수를 구분했습니다.
2. 개별 거래가 10000 이상인 금액만 더하던 식을 전체 거래금액 합계로 변경했습니다.
3. 고객별 합계와 날짜 수에 대한 두 조건을 HAVING에 적용했습니다. 첫 수정에서는 날짜 수 조건을 빠뜨려 추가했습니다.

### 최종 제출 쿼리

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT transaction_date) AS active_day_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_amount >= 10000
   AND active_day_count >= 3
ORDER BY
    active_day_count DESC,
    total_transaction_amount DESC,
    customer_id ASC;
```

### 실제 결과 일부

| customer_id | transaction_count | active_day_count | total_transaction_amount |
| --- | --- | --- | --- |
| FIN_CUSTOMER_027 | 6 | 6 | 14758.39 |
| FIN_CUSTOMER_028 | 6 | 6 | 12800.00 |
| FIN_CUSTOMER_029 | 6 | 6 | 12027.00 |
| FIN_CUSTOMER_019 | 5 | 5 | 201267.21 |
| FIN_CUSTOMER_020 | 5 | 5 | 74256.00 |

사용자가 공유한 출력의 앞부분입니다. 전체 결과 건수와 실행 시간은 확인되지 않았습니다.

### 꼭 구분할 부분

```sql
SUM(CASE WHEN transaction_amount >= 10000
         THEN transaction_amount ELSE 0 END)
```

위 식은 거래 한 건이 10000 이상인 금액만 합산합니다. 이번 문제는 모든 거래를 합친 뒤 고객별 합계가 10000 이상인지 HAVING으로 판단합니다. 4000씩 세 번 거래한 고객도 합계 12000으로 포함해야 합니다.
</details>

<details>
<summary>🧩 CTE 연습 1 — 고객별 누적 거래금액</summary>

## CTE 연습 1. 고객별 누적 거래금액

### 테이블 설명

bank_transactions의 한 행은 금융 거래 한 건입니다. 같은 고객이 같은 날 여러 번 거래할 수 있습니다. 아래는 필요한 컬럼 일부이며 NULL이 없습니다.

| 컬럼 | 자료형 | 의미 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer_id | VARCHAR(20) | 고객 ID |
| transaction_date | DATE | 거래 날짜 |
| transaction_amount | DECIMAL(15,2) | 거래금액 |

금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 새 문법: CTE

CTE는 한 SQL 문장 안에서 중간 결과에 이름을 붙여 사용하는 방식입니다. 원본 DB에 영구 테이블을 저장하는 명령은 아닙니다.

```sql
WITH 중간결과이름 AS (
    SELECT ...
)
SELECT ...
FROM 중간결과이름;
```

위 코드는 구조 설명용이며 그대로 실행할 SQL이 아닙니다.

### 문제 및 조건

고객별 전체 거래금액을 합산하는 customer_totals CTE를 만들고 고객 ID와 누적 금액을 조회합니다.

- 전체 기간의 모든 거래를 사용합니다.
- CTE 이름은 customer_totals입니다.
- 누적 금액 내림차순, 고객 ID 오름차순으로 정렬합니다.
- 중간 결과의 한 행은 고객 한 명입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| total_amount | 고객별 누적 거래금액 |

### 가상 예시

A가 4000과 7000을 거래했다면 중간 결과에는 A, 11000.00 한 행이 생깁니다. 바깥 SELECT는 이 결과를 조회합니다.

### 제출 쿼리

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
ORDER BY total_amount DESC, customer_id ASC;
```

### 실제 결과 일부

| customer_id | total_amount |
| --- | --- |
| FIN_CUSTOMER_030 | 1560034.99 |
| FIN_CUSTOMER_031 | 1380002.88 |
| FIN_CUSTOMER_032 | 991132.22 |

### 검증

정상 실행을 확인했습니다. 전체 결과 건수·실행 시간은 기록되지 않았습니다.
</details>

<details>
<summary>🧩 CTE 연습 2 — HAVING과 바깥 WHERE</summary>

## CTE 연습 2. 누적 거래금액 10000 이상인 고객

### 테이블 설명

bank_transactions의 한 행은 금융 거래 한 건입니다. 같은 고객이 같은 날 여러 번 거래할 수 있습니다. 아래는 필요한 컬럼 일부이며 NULL이 없습니다.

| 컬럼 | 자료형 | 의미 |
| --- | --- | --- |
| transaction_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer_id | VARCHAR(20) | 고객 ID |
| transaction_date | DATE | 거래 날짜 |
| transaction_amount | DECIMAL(15,2) | 거래금액 |

금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### CTE 결과 설명

customer_totals의 한 행은 고객 한 명의 누적 거래금액입니다. customer_id와 total_amount 두 컬럼을 만듭니다.

### 문제

고객별 전체 거래금액을 합산한 customer_totals CTE를 만들고, 누적 금액이 10000 이상인 고객을 조회합니다. 이번 작성 연습에서는 선별 조건을 CTE 바깥쪽 조회에 작성합니다.

### 조건

- 전체 기간의 모든 거래를 합산합니다.
- 정확히 10000인 고객도 포함합니다.
- 누적 금액 내림차순, 고객 ID 오름차순으로 정렬합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| total_amount | 고객별 누적 거래금액 |

### 가상 예시

| 고객 | 누적 금액 | 포함 여부 |
| --- | --- | --- |
| A | 11000.00 | 포함 |
| B | 9000.00 | 제외 |
| C | 10000.00 | 포함 |

A와 C를 금액 내림차순으로 출력합니다. B는 제외됩니다.

### 첫 제출 — HAVING 방식

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING total_amount >= 10000
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
ORDER BY total_amount DESC, customer_id ASC;
```

<b>이 쿼리는 계산 논리상 정답입니다.</b> 고객별 합계를 계산하고 10000 이상인 고객을 정확히 선별합니다. 다만 이번 연습에서 지정한 ‘바깥쪽에 조건 작성’과는 작성 위치가 달랐습니다.

### 바깥 WHERE 방식으로 작성

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM bank_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_amount
FROM customer_totals
WHERE total_amount >= 10000
ORDER BY total_amount DESC, customer_id ASC;
```

### 실제 결과 일부

두 방식의 실행 결과 앞부분은 동일합니다.

| customer_id | total_amount |
| --- | --- |
| FIN_CUSTOMER_030 | 1560034.99 |
| FIN_CUSTOMER_031 | 1380002.88 |
| FIN_CUSTOMER_032 | 991132.22 |

### 두 방식의 차이

| 조건 위치 | 문법 | 판단하는 대상 |
| --- | --- | --- |
| CTE 안 | HAVING | 고객별 집계 결과 |
| CTE 밖 | WHERE | CTE에 이미 만들어진 금액 컬럼 |

<b>이번 두 쿼리는 같은 결과를 계산합니다.</b> HAVING을 WHERE로 바꾼 것은 잘못된 계산을 고친 것이 아니라 CTE 결과를 일반 테이블처럼 사용하는 연습입니다.
두 쿼리는 같은 고객별 합계에 같은 조건을 적용하므로 결과가 같습니다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — 집계 대상·CTE</summary>

## 무엇을 세는지 구분하기

| 표현 | 의미 |
| --- | --- |
| COUNT(\*) | 거래 행 수 |
| COUNT(DISTINCT transaction_date) | 서로 다른 거래 날짜 수 |
| SUM(transaction_amount) | 모든 거래금액 합계 |

## 거래 조건과 고객 조건

- “5000 이상인 거래들의 금액 합계”: 각 거래를 판단하여 금액을 합산합니다.
- “누적 금액이 10000 이상인 고객”: 고객별 모든 금액을 합산한 후 고객을 선별합니다.

## CTE의 중간 결과

원본의 한 행은 거래 한 건입니다. 고객별로 집계한 CTE의 한 행은 고객 한 명입니다. total_amount는 CTE 안에서 계산하지만 바깥 조회에서는 이미 존재하는 컬럼처럼 사용할 수 있습니다.

## HAVING을 쓴 첫 코드도 논리는 맞음

이번 CTE 연습에서 안쪽 HAVING과 바깥 WHERE는 모두 올바른 결과를 구합니다. 두 조건이 어떤 위치에서나 항상 교환 가능하다는 뜻은 아닙니다. 여기서는 같은 고객별 합계에 같은 조건을 적용하여 결과가 같습니다.
논리적 설명 순서를 DB의 물리적 실행 순서로 단정하지 않습니다.
</details>

<details>
<summary>🧠 학습 회고·검증 범위·다음 연습</summary>

## 확인된 학습 상태

| 항목 | 상태 |
| --- | --- |
| 문제 1 | 첫 제출 쿼리 정답·3행 실행 결과 확인·DB 재검증 일치 |
| 문제 2 | 정답·실행 결과 확인 |
| 문제 3 | 정답·실행 결과 확인 |
| CTE 연습 1 | 고객별 합계 CTE 실행 확인 |
| CTE 연습 2 | HAVING과 WHERE 두 방식 실행·계산 논리 모두 정답 |

검증은 제출 SQL과 사용자가 공유한 출력에 근거합니다.

## 아직 완료하지 않은 부분

- CTE로 조건을 만족하는 전체 고객 수 계산
- CTE를 빈 화면에서 독립적으로 재작성
- 윈도우 함수 직접 작성 및 실행
고객 수 계산은 다음 연습으로 남겨 둡니다.

## 다음 연습 — 미실행

- [ ] 답을 보지 않고 고객별 합계 CTE 작성
- [ ] 누적 금액 조건을 만족하는 고객 수 계산
- [ ] 대상 고객들의 누적 금액 평균 계산
- [ ] 윈도우 함수의 행 유지 개념을 예제로 확인
</details>
</details>
