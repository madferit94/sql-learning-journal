# Day 06 — 학습 원기록

[English](../en/day06.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. Day06 고객 식별자는 가명 처리했습니다.

### 💳 Day6 — 거래 건수·금액·CASE WHEN 집계
# SQL 학습 기록 — Day 6
## Finance — 거래 건수·거래금액 집계
## 1. 오늘의 학습 목표
- 데이터베이스: `finance`
- 테이블: `bank_transactions`
- 환경: MySQL 8.4
- 전체 데이터: **1,048,567건**
- 거래일 범위: **2016-08-01 \~ 2016-10-21**
### 오늘 연습한 내용
- `COUNT()` — 거래 건수
- `SUM()` — 총 거래금액
- `AVG()` — 평균 거래금액
- `ROUND()` — 평균값 반올림
- `GROUP BY` — 날짜별·고객별·구간별 집계
- `HAVING` — 집계 결과 필터링
- `ORDER BY` — 다중 정렬 우선순위
- `CASE WHEN` — 거래금액 구간 분류
## 2. 주요 컬럼


| English column | 한국어 의미 | Table | 실제 역할 |
| --- | --- | --- | --- |
| `transaction_id` | 거래 ID | bank_transactions | 개별 거래 식별 |
| `customer_id` | 고객 ID | bank_transactions | 고객별 거래 집계 |
| `customer_dob` | 고객 생년월일 | bank_transactions | 향후 연령 분석 |
| `customer_gender` | 고객 성별 | bank_transactions | 고객 특성 분석 |
| `customer_location` | 고객 지역 | bank_transactions | 지역별 거래 분석 |
| `account_balance` | 계좌 잔액 | bank_transactions | 고객 잔액 분석 |
| `transaction_date` | 거래일 | bank_transactions | 날짜별 거래 집계 |
| `transaction_time` | 거래시간 | bank_transactions | 시간대별 분석 |
| `transaction_amount` | 거래금액(INR) | bank_transactions | 합계·평균·구간 분석 |


---
# 문제 1 — 전체 거래 건수와 총 거래금액
## 문제
전체 데이터의 **거래 건수와 총 거래금액**을 조회한다.
출력 컬럼:
- `transaction_count`
- `total_transaction_amount`
## 첫 시도
```sql
SELECT
    COUNT(*) transaction_date,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions;
```
## 문제점
계산 자체는 맞았다.
하지만 `COUNT(*)`의 alias를 `transaction_date`로 잘못 지정했다.
즉, **SQL 개념 오류가 아니라 alias 이름 오류**였다.
## 최종 쿼리
```sql
SELECT
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions;
```
## 실제 결과


| transaction_count | total_transaction_amount |
| --- | --- |
| 1,048,567 | 1,650,795,731.57 |


## 핵심 개념
```sql
COUNT(*)                 -- 전체 행 개수
SUM(transaction_amount)  -- 거래금액 합계
```
---
# 문제 2 — 거래일별 거래 건수와 총 거래금액
## 문제
거래일별로 다음을 계산한다.
- 거래 건수
- 총 거래금액
가장 이른 거래일부터 출력한다.
## 첫 시도
```sql
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY transaction_date;
```
**첫 시도 정답.**
## 최종 쿼리
```sql
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY transaction_date;
```
## 실제 결과
총 **55개 거래일**이 조회됐다.
일부 결과:


| transaction_date | transaction_count | total_transaction_amount |
| --- | --- | --- |
| 2016-08-01 | 20,438 | 29,801,816.34 |
| 2016-08-02 | 20,948 | 30,467,503.29 |
| 2016-08-03 | 20,615 | 31,149,483.67 |
| 2016-08-04 | 20,682 | 35,722,718.64 |
| 2016-08-05 | 21,112 | 34,833,933.12 |
| ... | ... | ... |
| 2016-09-30 | 1,951 | 3,316,668.50 |
| 2016-10-16 | 3 | 1,067.00 |
| 2016-10-21 | 3,656 | 7,663,951.63 |


## 핵심 개념
```sql
GROUP BY transaction_date
```
전체 거래를 **거래일별 그룹**으로 나눈 뒤 각 그룹에 `COUNT()`와 `SUM()`을 적용한다.
주의:
데이터에 모든 날짜가 연속적으로 존재하지 않는다.
또한 `2016-10-16`은 거래가 3건뿐이다.
하지만 이것만으로 데이터 오류라고 판단하지 않는다.
---
# 문제 3 — 거래일별 평균 거래금액
## 문제
거래일별로 다음을 계산한다.
- 거래 건수
- 총 거래금액
- 평균 거래금액
평균 거래금액은 **소수점 둘째 자리까지 반올림**하고, 평균 거래금액이 높은 날짜부터 출력한다.
## 첫 시도
```sql
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY avg_transaction_amount DESC;
```
**첫 시도 정답.**
## 최종 쿼리
```sql
SELECT
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY avg_transaction_amount DESC;
```
## 실제 결과 상위


| transaction_date | transaction_count | total_transaction_amount | avg_transaction_amount |
| --- | --- | --- | --- |
| 2016-10-21 | 3,656 | 7,663,951.63 | 2,096.27 |
| 2016-08-15 | 24,171 | 44,313,092.06 | 1,833.32 |
| 2016-09-22 | 6,971 | 12,746,612.34 | 1,828.52 |
| 2016-08-06 | 26,585 | 47,527,227.82 | 1,787.75 |
| 2016-08-14 | 25,596 | 45,732,820.10 | 1,786.72 |


총 **55행**.
## 핵심 개념
중첩 함수는 안쪽부터 계산한다.
```sql
ROUND(AVG(transaction_amount), 2)
```
계산 순서:
`transaction_amount`
→ `AVG()`
→ 평균 거래금액
→ `ROUND(..., 2)`
→ 소수점 둘째 자리 반올림
### 해석 시 주의
**평균 거래금액이 가장 높은 날짜 = 총 거래금액이 가장 높은 날짜**
가 아니다.
평균, 합계, 거래 건수는 서로 다른 지표다.
---
# 문제 4 — 거래가 5건 이상인 고객
## 문제
고객별로 다음을 계산한다.
- 거래 건수
- 총 거래금액
조건:
- 거래 건수가 5건 이상인 고객만 조회
- 거래 건수가 많은 고객부터 출력
- 거래 건수가 같으면 총 거래금액이 높은 고객부터 출력
## 첫 시도
```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY transaction_count
HAVING transaction_count >= 5
ORDER BY total_transaction_amount ASC, transaction_count DESC;
```
## 첫 번째 문제점 — GROUP BY 기준
문제는 **고객별 분석**이다.
따라서:
```sql
GROUP BY customer_id
```
가 필요하다.
`transaction_count`는 고객별로 집계한 뒤 만들어지는 결과이지 고객을 묶는 기준이 아니다.
## 두 번째 시도
```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 5
ORDER BY total_transaction_amount ASC, transaction_count DESC;
```
`GROUP BY`와 `HAVING`은 수정했다.
하지만 정렬 조건이 잘못됐다.
문제에서는:
1. 거래 건수
2. 총 거래금액
순서로 정렬해야 한다.
## 세 번째 시도
```sql
ORDER BY total_transaction_amount DESC, transaction_count DESC;
```
`DESC` 방향은 수정했지만 여전히 총 거래금액이 **1순위**였다.
SQL의 다중 정렬은 **왼쪽 컬럼부터 우선 적용**한다.
## 최종 쿼리
```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 5
ORDER BY
    transaction_count DESC,
    total_transaction_amount DESC;
```
## 실제 결과 상위


| customer_id | transaction_count | total_transaction_amount |
| --- | --- | --- |
| CUSTOMER_001 | 6 | 37,873.00 |
| CUSTOMER_010 | 6 | 21,597.50 |
| CUSTOMER_002 | 6 | 14,758.39 |
| CUSTOMER_005 | 6 | 12,800.00 |
| CUSTOMER_004 | 6 | 12,027.00 |
| CUSTOMER_003 | 6 | 9,796.03 |
| CUSTOMER_007 | 6 | 8,503.00 |
| CUSTOMER_009 | 6 | 8,375.74 |
| CUSTOMER_008 | 6 | 5,825.00 |
| CUSTOMER_006 | 6 | 5,722.78 |


## 핵심 개념 1 — WHERE vs HAVING
```sql
WHERE
```
→ `GROUP BY` 전에 원본 행을 필터링
```sql
HAVING
```
→ `GROUP BY` 후 만들어진 집계 결과를 필터링
따라서:
```sql
HAVING transaction_count >= 5
```
를 사용한다.
## 핵심 개념 2 — 다중 ORDER BY
```sql
ORDER BY
    transaction_count DESC,
    total_transaction_amount DESC;
```
정렬 우선순위:
1. `transaction_count DESC`
2. 거래 건수가 같을 때 `total_transaction_amount DESC`
즉 `ORDER BY A, B`에서는 **A가 1순위, B가 2순위**다.
---
# 문제 5 — 거래금액 구간별 거래 분석
## 문제
각 거래를 거래금액에 따라 다음과 같이 분류한다.
- `1,000 미만` → `Small`
- `1,000 이상 5,000 미만` → `Medium`
- `5,000 이상` → `Large`
각 구간별로:
- 거래 건수
- 총 거래금액
을 계산하고 거래 건수가 많은 구간부터 출력한다.
## 주요 시행착오 1 — CASE 문법
초기 작성:
```sql
WHEN transaction_amount < 5000, THEN 'Medium'
```
`WHEN 조건 THEN 결과` 사이에는 쉼표가 들어가지 않는다.
올바른 구조:
```sql
WHEN transaction_amount < 5000 THEN 'Medium'
```
## 주요 시행착오 2 — THEN 누락
```sql
WHEN transaction_amount >= 1000
     AND transaction_amount < 5000 'Medium'
```
`'Medium'` 앞에 `THEN`이 필요했다.
기본 구조:
```sql
WHEN 조건 THEN 결과
```
## 주요 시행착오 3 — 경계값
```sql
WHEN transaction_amount > 5000 THEN 'Large'
```
라고 작성하면 정확히 `5000`인 거래가 포함되지 않는다.
문제 조건은 **5000 이상**이므로:
```sql
WHEN transaction_amount >= 5000 THEN 'Large'
```
가 필요하다.
## 주요 시행착오 4 — SELECT 컬럼 사이 쉼표
```sql
END AS amount_category
COUNT(*) AS transaction_count
SUM(transaction_amount) AS total_transaction_amount
```
처럼 작성했다.
SELECT에서 여러 표현식을 출력하려면 쉼표가 필요하다.
```sql
END AS amount_category,
COUNT(*) AS transaction_count,
SUM(transaction_amount) AS total_transaction_amount
```
## 주요 시행착오 5 — GROUP BY 누락
CASE와 집계함수를 정상적으로 작성한 뒤 `GROUP BY`를 빠뜨려 MySQL에서 다음 오류가 발생했다.
```plain text
ERROR 1140
IN aggregated query without GROUP BY...
```
`amount_category`별 집계이므로:
```sql
GROUP BY amount_category
```
가 필요하다.
## 주요 시행착오 6 — Alias 오타
한 시도에서:
```sql
END AS amount_categoy
```
라고 작성한 뒤:
```sql
GROUP BY amount_category
```
를 사용했다.
alias 이름이 서로 달라서:
```plain text
ERROR 1054
Unknown column 'amount_category' IN 'GROUP statement'
```
가 발생했다.
## 최종 쿼리
```sql
SELECT
    CASE
        WHEN transaction_amount < 1000 THEN 'Small'
        WHEN transaction_amount >= 1000
             AND transaction_amount < 5000 THEN 'Medium'
        WHEN transaction_amount >= 5000 THEN 'Large'
    END AS amount_category,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY amount_category
ORDER BY transaction_count DESC;
```
## 실제 결과


| amount_category | transaction_count | total_transaction_amount |
| --- | --- | --- |
| Small | 728,139 | 228,135,223.55 |
| Medium | 262,969 | 532,506,983.51 |
| Large | 57,459 | 890,153,524.51 |


## 검증
거래 건수 합계:
```plain text
728,139
+ 262,969
+ 57,459
= 1,048,567
```
원본 테이블의 전체 거래 건수:
```plain text
1,048,567
```
따라서 세 구간의 거래 건수 합계와 전체 데이터 행 수가 일치한다.
## 결과 해석
거래 건수:
```plain text
Small > Medium > Large
```
총 거래금액:
```plain text
Large > Medium > Small
```
즉 **거래 빈도가 가장 높은 구간과 거래금액 기여도가 가장 높은 구간은 다르다.**
Small 거래는 가장 자주 발생하지만, 총 거래금액은 Large 구간이 가장 크다.
---
# 오늘의 핵심 정리
## 1. GROUP BY 기준 찾기
문제에서 **“무엇별”**인지 먼저 찾는다.
```plain text
거래일별 → GROUP BY transaction_date
고객별   → GROUP BY customer_id
금액구간별 → GROUP BY amount_category
```
집계 결과 자체를 그룹 기준으로 잡는 것이 아니라 **분석 단위가 되는 컬럼**을 찾는다.
## 2. WHERE와 HAVING
```plain text
WHERE  → 집계 전 원본 데이터 조건
HAVING → 집계 후 결과 조건
```
예:
```sql
GROUP BY customer_id
HAVING COUNT(*) >= 5
```
## 3. ORDER BY 우선순위
```sql
ORDER BY A DESC, B DESC;
```
의 의미:
```plain text
1순위 → A
2순위 → B
```
따라서 문제에서 제시한 정렬 우선순위를 그대로 왼쪽부터 작성한다.
## 4. 중첩 함수는 안쪽부터
```sql
ROUND(AVG(transaction_amount), 2)
```
계산 순서:
```plain text
AVG()
↓
ROUND()
```
## 5. CASE WHEN 기본 구조
```sql
CASE
    WHEN 조건1 THEN 결과1
    WHEN 조건2 THEN 결과2
    WHEN 조건3 THEN 결과3
END AS alias
```
CASE와 집계함수를 같이 사용할 경우:
```sql
SELECT
    CASE
        WHEN ... THEN ...
        WHEN ... THEN ...
    END AS category,
    COUNT(*) AS COUNT,
    SUM(column) AS total
FROM TABLE
GROUP BY category;
```
---
# 오늘의 오류 패턴
### 개념적으로 다시 볼 부분
1. `GROUP BY`에 어떤 컬럼을 넣어야 하는지
2. 다중 `ORDER BY`의 정렬 우선순위
3. `CASE WHEN` 결과를 다시 그룹화하는 구조
4. 거래금액 구간의 경계값 처리
### 단순 작성 실수
- `SELECT` → `ELECT`
- `transaction_amount` → `transactions_amount`
- `amount_category` → `amount_categoy`
- `THEN` 누락
- `END` 누락
- SELECT 컬럼 사이 `,` 누락
- 따옴표 `'` 누락
단순 오타와 개념 오류는 구분해서 볼 필요가 있다.
---
# 오늘의 회고
## 잘 된 점
- `COUNT()`, `SUM()`, `AVG()` 기본 집계는 안정적으로 작성했다.
- 문제 2의 날짜별 `GROUP BY`는 첫 시도에 해결했다.
- 문제 3의 `ROUND(AVG(transaction_amount), 2)`도 첫 시도에 정확하게 작성했다.
- `HAVING`을 사용해야 한다는 점은 문제 4 첫 시도부터 알고 있었다.
- 문제 5에서는 여러 오류를 수정하면서 최종적으로 `CASE WHEN + GROUP BY + 집계함수`를 완성했다.
## 보완할 점
현재 가장 필요한 것은 새로운 문법을 계속 추가하는 것보다 **이미 알고 있는 문법을 긴 SQL 안에서 정확하게 조립하는 능력**이다.
특히 쿼리가 길어질 때:
```plain text
CASE
→ END AS alias
→ ,
→ COUNT/SUM
→ FROM
→ GROUP BY
→ HAVING
→ ORDER BY
```
순서를 확인하는 습관이 필요하다.
문제 5에서 발생한 오류 대부분은 `CASE WHEN`의 의미를 몰라서라기보다 **THEN, END, 쉼표, alias, 컬럼명 등을 동시에 관리하는 과정에서 발생한 오류**였다.
---
# 다음 학습 포인트 — Finance Day 2
다음 세션에서는 **고객 단위 거래 패턴 분석**을 진행한다.
오늘 약했던 내용을 바로 반복하기 위해 `CASE WHEN`을 다시 사용한다.
주요 방향:
```plain text
고객별 집계
→ CASE WHEN
→ 고객 거래 패턴 분류
→ 조건별 집계
→ 결과 검증
```
그 이후 Finance 학습에서는:
```plain text
월별 거래 분석
→ CTE
→ ROW_NUMBER / RANK / DENSE_RANK
→ LAG / LEAD
→ SUM() OVER()
→ AVG() OVER()
```
순으로 확장한다.

---
