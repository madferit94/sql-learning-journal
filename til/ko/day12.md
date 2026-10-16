# Day 12 — 2026-10-10

[English](../en/day12.md) · [목차](../../README.ko.md)

노션의 상세 기록을 공개용으로 정리했습니다. SQL·실행 결과는 당시 기록이며 게시를 위해 재실행하지 않았습니다. 거래 연습 데이터의 식별자는 가명 처리했습니다.

# Finance SQL Day (2026-10-10)
**학습일:** 2026-10-10
**환경:** MySQL / finance / bank_transactions
**학습 범위:** 고객별 집계, WHERE·HAVING, 조건부 집계, 비율, 서브쿼리 2단계 집계
**문제:** P1\~P5. **누적 SQL Day:** Day12. 기존 Day1\~Day11 다음 학습 기록으로 확인하여 2026-10-11에 번호를 보완했다.
**검증 근거:** 사용자 직접 실행 결과와 원본 검증 쿼리 결과. 이번 편집에서 AI가 DB에 접속해 재실행하지 않았다.
첫 시도의 오류와 도움받은 과정을 보존하며 SQL은 가독성을 위해 줄바꿈했다.
## 접속 및 테이블 확인
일반 터미널:
```bash
mysql --local-infile=1 -u root -p
```
MySQL 내부:
```sql
USE finance;
SHOW TABLES;
DESCRIBE bank_transactions;
SELECT * FROM bank_transactions LIMIT 5;
```
타입·NULL 여부는 기존 인계 문서 기준이다. 원본 한 행은 거래 1건이다.

| 컬럼 | 타입 | NULL 허용 | 의미 |
| --- | --- | --- | --- |
| transaction_id | VARCHAR(20) | 아니요 | 거래 ID |
| customer_id | VARCHAR(20) | 아니요 | 고객 ID |
| transaction_amount | DECIMAL(15,2) | 아니요 | 거래금액 |


### 📚 문제 1\~4 — 고객별 집계·조건부 집계·비율
## P1 / 5 — 거래가 활발한 고객 찾기
### 1. 문제
고객별 거래 건수, 총 거래금액, 평균 거래금액을 조회한다.
- 거래가 5건 이상인 고객만 출력한다.
- 평균 거래금액은 소수점 둘째 자리까지 반올림한다.
- 총 거래금액 내림차순, 동률이면 고객 ID 오름차순으로 정렬한다.
- 출력: customer_id, transaction_count, total_transaction_amount, avg_transaction_amount
**최종 결과 한 행:** 고객 1명
### 2. 내 첫 시도
```sql
SELECT customer_id, COUNT(*) AS transaction,
       SUM(transaction_amount) AS total_transaction_amount,
       ROUND(AVG(transaction_amoiunt), 2) AS avg_transaction
FROM bank_transactions
GROUP BY customer_id
ORDER BY total_transaction_amount DESC, customer_id ASC;
```
### 3. 실행 결과·오류
첫 실행에서 컬럼명 오타로 ERROR 1054가 발생했다.
```text
Unknown column 'transaction_amoiunt' in 'field list'
```
transaction_amount로 직접 수정한 뒤에는 실행됐으나, 거래 5건 이상 조건이 없어 거래가 1·2·4건인 고객도 나왔다.
이후 SELECT에는 COUNT(\*) AS transaction을 유지하고 HAVING(transaction_count) \>= 5를 추가하여 다음 오류가 발생했다.
```text
Unknown column 'transaction_count' in 'having clause'
```
HAVING의 괄호를 제거한 뒤에도 같은 오류가 반복됐다.
### 4. 틀린 이유
- transaction_amoiunt는 존재하지 않는 컬럼명이었다.
- 고객별 거래 건수 필터가 빠져 있었다.
- SELECT에서 만든 transaction과 HAVING에서 사용한 transaction_count가 달랐다. 괄호 문제가 아니었다.
- 평균 컬럼명 avg_transaction도 요구한 avg_transaction_amount로 수정했다.
### 5. 수정 쿼리
```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 5
ORDER BY total_transaction_amount DESC, customer_id ASC;
```
### 6. 검증
**사용자 실제 실행 결과 중 일부**

| customer_id | transaction_count | total_transaction_amount | avg_transaction_amount |
| --- | --- | --- | --- |
| FIN_CUSTOMER_019 | 5 | 201267.21 | 40253.44 |
| FIN_CUSTOMER_020 | 5 | 74256.00 | 14851.20 |
| FIN_CUSTOMER_025 | 5 | 38573.00 | 7714.60 |
| FIN_CUSTOMER_007 | 6 | 37873.00 | 6312.17 |

제공된 161행에서 거래 건수 5 이상, 고객 ID 중복 없음, 정렬, 합계÷건수의 반올림과 평균 일치를 확인했다.
예: 201267.21 ÷ 5 = 40253.442 → 40253.44
**상태:** 검증 완료 — 사용자 실행 결과 기준
**작성 과정:** 기본 집계 직접 작성 → AI 피드백 후 필터·별칭 수정
### 7. 핵심 개념 정리
AS는 계산 결과에 이름을 붙인다. 뒤에서 사용할 이름과 정확히 일치해야 한다. 고객별로 계산한 거래 건수의 조건은 HAVING에 작성한다.
---
## P2 / 5 — 일정 금액 이상 거래를 반복한 고객
### 1. 문제
거래금액이 1,000 이상인 거래만 대상으로 고객별 거래 건수와 평균 거래금액을 구한다.
- 해당 거래가 3건 이상인 고객만 출력한다.
- 평균은 소수점 둘째 자리까지 반올림한다.
- 거래 건수 내림차순, 동률이면 고객 ID 오름차순으로 정렬한다.
- 출력: customer_id, transaction_count, avg_transaction_amount
**최종 결과 한 행:** 금액이 1,000 이상인 거래가 3건 이상인 고객 1명
### 2. 내 첫 시도
```sql
SELECT customer_id, COUNT(*) AS transaction_count,
       ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING transaction_count >= 3 AND avg_transaction_amount >= 1000
ORDER BY transaction_count DESC, avg_transaction_amount ASC;
```
### 3. 실행 결과·오류
쿼리는 실행됐지만 전체 거래가 3건 이상이고 평균 거래금액이 1,000 이상인 고객을 골랐다. 문제는 개별 거래금액이 1,000 이상인 거래만 먼저 남기라는 조건이었다. 동률 정렬 기준도 평균이 아닌 고객 ID여야 했다.
### 4. 틀린 이유
개별 거래 조건과 고객별 집계 조건을 혼동했다.
**가상 반례:** 거래금액이 100, 200, 5700이면 전체 3건·평균 2000이므로 첫 쿼리는 통과한다. 그러나 1,000 이상 거래는 1건이므로 문제에서는 제외되어야 한다.
수정 과정에서 SUM(transaction_amount) AS total_transaction_amount를 추가했으나, 사용자가 “total 실수로 만듦”이라고 설명했다. 불필요한 출력 컬럼 추가 실수로 구분하고 최종 쿼리에서 제거했다.
### 5. 수정 쿼리
```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
WHERE transaction_amount >= 1000
GROUP BY customer_id
HAVING transaction_count >= 3
ORDER BY transaction_count DESC, customer_id ASC;
```
### 6. 검증
**사용자 실제 실행 결과 중 일부**

| customer_id | transaction_count | avg_transaction_amount |
| --- | --- | --- |
| FIN_CUSTOMER_006 | 4 | 8505.00 |
| FIN_CUSTOMER_012 | 4 | 1148.75 |
| FIN_CUSTOMER_015 | 4 | 1925.00 |
| FIN_CUSTOMER_016 | 4 | 1694.50 |

C1038492는 P1에서 5건·총액 34365.64·평균 6873.13이었다. P2 수정 과정의 총액 출력에서는 4건·총액 34020.01·평균 8505.00이었다.
34365.64 − 34020.01 = 345.63인 거래가 제외되어 건수·총액·평균이 바뀌었다.
**상태:** 최종 쿼리와 제공된 실행 결과 범위에서 검증 완료. 전체 출력 건수는 확인하지 못했다.
**작성 과정:** 직접 작성 → AI 피드백 후 WHERE·HAVING·정렬 수정 → 불필요한 출력 컬럼 제거
### 7. 핵심 개념 정리
WHERE에서 거래를 먼저 거르면 이후 COUNT와 AVG는 남은 거래만 대상으로 계산한다. 이번 COUNT는 전체 거래가 아니라 1,000 이상인 거래의 건수다.
---
## P3 / 5 — 고객별 고액 거래 건수 조회하기
### 1. 문제
전체 거래가 5건 이상인 고객의 전체 거래 건수와 고액 거래 건수를 조회한다.
- 고액 거래는 금액이 5,000 이상인 거래다.
- 고액 거래가 없는 고객도 포함하고 건수는 0으로 표시한다.
- 고액 거래 건수 내림차순, 동률이면 고객 ID 오름차순으로 정렬한다.
- 출력: customer_id, total_transaction_count, high_amount_count
### 2. 내 첫 시도
```sql
SELECT customer_id, COUNT(*) AS total_transaction_count, high_amount_count
FROM bank_transactions
(SELECT transaction_amount
 FROM bank_transactions
 WHERE transaction_amount >= 5000) AS amount_count
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_count DESC, customer_id ASC;
```
### 3. 실행 결과·오류
첫 시도의 실제 실행 오류 메시지는 공유되지 않았다. 코드 검토에서 high_amount_count 미정의, 연결 없이 붙인 서브쿼리, 건수 대신 금액 목록을 조회한 문제를 확인했다.
### 4. 틀린 이유
전체 거래를 유지하면서 조건에 맞는 거래만 따로 세어야 했다.
AI가 COUNT(CASE WHEN 조건 THEN 1 END) 구조를 힌트로 제공했다. 조건을 만족하면 1, 아니면 NULL이 되고 COUNT는 NULL을 제외한다.
### 5. 수정 쿼리
```sql
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_count DESC, customer_id ASC;
```
### 6. 검증
**사용자 실제 실행 결과 중 일부**

| customer_id | total_transaction_count | high_amount_count |
| --- | --- | --- |
| FIN_CUSTOMER_006 | 5 | 2 |
| FIN_CUSTOMER_014 | 5 | 2 |
| FIN_CUSTOMER_007 | 6 | 1 |
| FIN_CUSTOMER_005 | 6 | 0 |

전체 제공 결과 161행에서 고액 거래 2건 고객 7명, 1건 고객 44명, 0건 고객 110명이었다. 고객 목록과 전체 거래 건수가 P1과 일치했고, 건수 조건과 정렬도 확인했다.
**상태:** 검증 완료 — 사용자 실행 결과 기준
**작성 과정:** 직접 서브쿼리 시도 → AI의 조건부 COUNT 힌트 → 직접 수정·실행
### 7. 핵심 개념 정리
전체 거래는 COUNT(\*)로 세고 고액 거래는 CASE WHEN으로 따로 센다. 전체 거래도 필요하므로 고액 거래 조건으로 원본을 먼저 제외하지 않는다.
---
## P4 / 5 — 고객별 고액 거래 비율 조회하기
### 1. 문제
전체 거래가 5건 이상인 고객의 전체 거래 건수, 고액 거래 건수, 고액 거래 비율을 조회한다.
- 고액 거래: 금액 5,000 이상
- 비율 = 고액 거래 건수 ÷ 전체 거래 건수 × 100
- 비율은 소수점 둘째 자리까지 반올림한다.
- 고액 거래가 없는 고객도 포함하고 비율을 0.00으로 표시한다.
- 비율 내림차순, 동률이면 고객 ID 오름차순으로 정렬한다.
- 출력: customer_id, total_transaction_count, high_amount_count, high_amount_rate
### 2. 내 첫 시도
```sql
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        SUM(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_rate DESC, customer_id ASC;
```
### 3. 실행 결과·오류
실행은 성공했지만 고액 거래가 없는 고객 110명의 비율이 NULL이었다.

| customer_id | total_transaction_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| FIN_CUSTOMER_006 | 5 | 2 | 40.00 |
| FIN_CUSTOMER_007 | 6 | 1 | 16.67 |
| FIN_CUSTOMER_005 | 6 | 0 | NULL |

사용자는 “고액거래가 없는 고객도 포함해 달라고 해서 했다”고 설명했다. 고객을 포함한 것은 맞았고, 수정 대상은 포함 여부가 아니라 비율의 NULL 처리였다. 이후 수정 전 결과를 다시 공유한 단계도 있었으며, 최종 공유에서 ELSE 0 반영이 확인됐다.
### 4. 틀린 이유
ELSE를 생략하면 조건에 맞지 않을 때 NULL이다. 고액 거래가 없으면 SUM의 입력이 모두 NULL이므로 합계도 NULL이다. COUNT는 NULL만 있으면 0을 반환한다.
비율 분자의 SUM에는 ELSE 0을 넣는다. 반대로 조건부 COUNT에 ELSE 0을 넣으면 0도 세므로 전체 거래 건수가 된다.
### 5. 수정 쿼리
```sql
SELECT
    customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        SUM(CASE WHEN transaction_amount >= 5000 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY high_amount_rate DESC, customer_id ASC;
```
### 6. 검증
**수정 후 사용자 실제 결과 중 일부**

| customer_id | total_transaction_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| FIN_CUSTOMER_006 | 5 | 2 | 40.00 |
| FIN_CUSTOMER_007 | 6 | 1 | 16.67 |
| FIN_CUSTOMER_022 | 5 | 0 | 0.00 |

최종 제공된 115행에서 비율 산술, 거래 건수 조건, 정렬이 맞았고 NULL 비율이 없었다.
**상태:** 최종 쿼리와 제공된 실행 결과 범위에서 검증 완료. 최종 첨부가 중간에서 끝나 전체 출력 건수는 확인하지 못했다.
**작성 과정:** 비율 계산 직접 시도 → AI 피드백 후 ELSE 0 추가 → 직접 재실행
### 7. 핵심 개념 정리
고객을 결과에 포함하는 것과 비율을 0으로 표시하는 것은 별개다. 조건부 SUM에서는 조건에 맞지 않는 거래를 0으로 처리해야 고액 거래가 없는 고객의 비율도 0이 된다.


### 🧩 문제 5 — 서브쿼리로 거래 횟수별 고객 수 구하기
## P5 / 5 — 거래 횟수별 고객 수 조회하기
### 1. 문제
전체 기간의 고객별 거래 횟수를 기준으로 같은 거래 횟수의 고객이 각각 몇 명인지 조회한다. 금액 제한 없이 transaction_count, customer_count를 출력하고 거래 횟수 오름차순으로 정렬한다.
**최종 결과 한 행:** 거래 횟수 한 종류
### 2. 내 첫 시도 — 안쪽 집계
```sql
SELECT customer_id, COUNT(*) AS transaction_count
FROM bank_transactions
GROUP BY customer_id
ORDER BY transaction_count DESC;
```
사용자가 직접 작성하고 정상 실행했다.

| customer_id | transaction_count |
| --- | --- |
| FIN_CUSTOMER_024 | 6 |
| FIN_CUSTOMER_018 | 6 |
| FIN_CUSTOMER_007 | 6 |
| FIN_CUSTOMER_005 | 6 |

**중간 표 한 행:** 고객 1명. 안쪽 COUNT(\*)는 고객의 거래 행을 센다.
### 3. 바깥 집계 첫 시도
AI가 서브쿼리 틀과 빈칸을 제공한 뒤 작성했다.
```sql
SELCET COUNT(*) AS transaction_count, COUNT(*) AS customer_count
FROM (SELECT
 customer_id,
 COUNT(*) AS transaction_count
FROM bank_transactions
GROUP BY customer_id
) AS customer_transactions
GROUP BY transaction_count
ORDER transaction_count ASC;
```
### 4. 실행 결과·오류와 틀린 이유
실제 오류 메시지는 공유되지 않았다. 코드 검토에서 SELCET 오타, ORDER BY의 BY 누락, 바깥 COUNT(\*) 중복 사용을 확인했다.
바깥에서는 중간 표의 transaction_count 값을 출력하고, 그 그룹의 행을 COUNT(*)로 세어야 했다. COUNT(*)를 두 번 쓰면 고객 수를 두 번 출력한다.
사용자가 수정한 쿼리는 구조상 맞았다. 이후 사용자가 실행 오류를 보고했으나 메시지가 없어 정확한 원인은 확인하지 못했다. AI가 전체 코드를 정리해 다시 제공했고 사용자가 실행했다. 특수 공백이 원인이었다고 확정하지 않는다.
### 5. 수정 쿼리 — 최종 답안
```sql
SELECT
    transaction_count,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count
    FROM bank_transactions
    GROUP BY customer_id
) AS customer_transactions
GROUP BY transaction_count
ORDER BY transaction_count ASC;
```
**작성 과정:** 안쪽 집계 직접 작성·실행 → AI 틀을 바탕으로 바깥 집계 작성 → 피드백 반영 → AI가 정리한 전체 코드로 최종 실행. 완전한 독립 해결로 평가하지 않는다.
### 6. 실제 결과와 검증

| transaction_count | customer_count |
| --- | --- |
| 1 | 740653 |
| 2 | 124960 |
| 3 | 16789 |
| 4 | 1702 |
| 5 | 147 |
| 6 | 14 |

고객 수 합계: 740653 + 124960 + 16789 + 1702 + 147 + 14 = 884265명
거래 수 합계: 1×740653 + 2×124960 + 3×16789 + 4×1702 + 5×147 + 6×14 = 1048567건
AI가 제공한 원본 검증 쿼리를 사용자가 실행했다.
```sql
SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT customer_id) AS total_customers
FROM bank_transactions;
```

| total_transactions | total_customers |
| --- | --- |
| 1048567 | 884265 |

두 값 모두 P5로 계산한 합계와 일치했다. 5회 이상 거래 고객도 147 + 14 = 161명으로 P1·P3과 일치했다.
**상태:** 검증 완료 — 사용자 실행 결과 및 원본 집계 대조 기준
### 7. 집계 구조
```text
원본: 한 행 = 거래 1건
  ↓ GROUP BY customer_id
중간 표: 한 행 = 고객 1명
  ↓ GROUP BY transaction_count
최종 표: 한 행 = 거래 횟수 한 종류
```
customer_transactions는 안쪽 SELECT 결과에 붙인 표 이름이다. 실제 DB에 새 테이블을 저장한 것은 아니다.
### 8. 내 말로 정리·현재 이해 상태
**사용자 직접 표현:** 문장을 볼 때 CASE WHEN이나 서브쿼리를 쓰는 것이 아직 머릿속에서 정리가 잘 안 된다. CASE WHEN은 다시 풀면 구현이 가능하지만 서브쿼리는 구현이 힘들다.
사용자는 바깥 COUNT가 고객 수인 이유에 대해 “거래 건수랑 고객 수를 같이 구하는 문제여서? 안쪽 쿼리를 먼저 실행하기 때문?”이라고 질문했다.
**AI 설명:** 안쪽 결과를 바깥에서 사용하는 방향은 맞다. 고객 수가 되는 이유는 안쪽 GROUP BY customer_id가 고객 한 명을 한 행으로 만들었기 때문이다. 설명용 논리 흐름이며 DB의 물리적 실행 순서를 단정하는 것은 아니다.
**추가 이해 확인:** 가상 고객 A·B가 2회, C가 1회 거래한 상황에 D가 2회 거래하면 2회 그룹의 고객 수는 3명이다. 사용자는 D만 보고 1명이라고 답했고, 그룹에 A·B·D가 함께 포함됨을 설명했다.
**이해 상태:** 설명은 제공했으나 이후 독립 설명·재구현은 아직 확인하지 못했다.


### 🔎 오늘 꼭 이해해야 할 부분 — WHERE·CASE WHEN·서브쿼리
## 오늘 꼭 이해해야 할 부분 — 설명과 연습
아래는 AI가 작성한 보충 설명이다. 읽었다는 사실을 숙달로 기록하지 않는다. 예시는 모두 가상이며 실제 금융 데이터 결과와 구분한다.
### 1. 문장에서 문법 이름보다 결과 표를 먼저 생각하기

| 판단 질문 | 오늘 사용한 방식 | 예시 |
| --- | --- | --- |
| 조건에 맞는 거래만 분석할 것인가? | WHERE | 1,000 이상 거래만 남겨 고객별 건수 계산 |
| 전체 거래를 유지하며 일부만 따로 셀 것인가? | CASE WHEN + 집계함수 | 전체 거래 건수와 고액 거래 건수를 함께 출력 |
| 고객별로 계산한 값을 다시 묶어야 하는가? | 중간 표를 만드는 서브쿼리 | 거래 횟수가 같은 고객이 몇 명인지 계산 |

특정 단어가 있으면 무조건 특정 문법을 쓰는 규칙은 아니다. CASE WHEN과 서브쿼리는 함께 쓸 수도 있다. 오늘은 가장 단순한 구조를 기준으로 판단한다.
### 2. WHERE와 HAVING — 무엇을 검사하는가?
가상 거래금액이 100, 200, 5700이면 평균은 2000이지만 1,000 이상 거래는 한 건이다.
- WHERE transaction_amount \>= 1000: 거래 한 건의 금액을 검사하고 해당 거래만 남긴다.
- HAVING COUNT(\*) \>= 3: 고객별로 묶은 뒤 남은 거래가 3건 이상인지 검사한다.
- HAVING AVG(transaction_amount) \>= 1000: 고객 평균이 1,000 이상인지 검사한다. 개별 거래금액 조건과 다르다.
**생각 순서:** 어떤 거래를 남길까 → 무엇별로 묶을까 → 묶은 결과 중 무엇을 남길까.
### 3. CASE WHEN — 행마다 반환할 값을 정하기
금액 1000, 5000, 8000인 거래가 있다고 가정한다.

| 거래금액 | THEN 1 END | THEN 1 ELSE 0 END |
| --- | --- | --- |
| 1000 | NULL | 0 |
| 5000 | 1 | 1 |
| 8000 | 1 | 1 |

COUNT는 NULL이 아닌 값의 개수를 센다. SUM은 숫자 값을 더한다.

| 상황 | COUNT(CASE WHEN 조건 THEN 1 END) | SUM(CASE WHEN 조건 THEN 1 ELSE 0 END) |
| --- | --- | --- |
| 위 예시 | 2 | 2 |
| 조건에 맞는 거래가 없음 | 0 | 0 |

**왜 두 함수의 ELSE 처리가 다른가?**
- COUNT의 입력이 0, 0, 0이면 0도 값이므로 결과는 3이다.
- SUM의 입력이 0, 0, 0이면 합계는 0이다.
- SUM의 입력이 전부 NULL이면 합계는 NULL이다.
따라서 오늘 조건부 건수에는 다음 두 방식이 가능하다.
```sql
COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END)
SUM(CASE WHEN transaction_amount >= 5000 THEN 1 ELSE 0 END)
```
### 4. 비율 — 분자·분모·대상 확인
P4의 분자는 고액 거래 건수, 분모는 같은 고객의 전체 거래 건수이다. WHERE로 고액 거래만 남기면 분모도 고액 거래 건수가 되어 원래 질문과 달라진다.
전체 거래 6건 중 고액 거래가 없으면 0 ÷ 6 × 100 = 0%이다. NULL은 0과 같은 값이 아니다.
P4에서는 전체 거래 5건 이상인 그룹만 남기므로 분모가 0인 경우가 없다.
### 5. 서브쿼리 — 먼저 만들어야 하는 표 찾기
최종 질문: 거래 횟수가 같은 고객이 몇 명인가?
원본의 한 행은 거래이므로 바로 행을 세면 거래 건수다. 먼저 고객별 거래 횟수 표가 필요하다.
**가상 원본**

| transaction_id | customer_id |
| --- | --- |
| T1 | A |
| T2 | A |
| T3 | B |
| T4 | B |
| T5 | C |
| T6 | D |
| T7 | D |

**안쪽 쿼리의 결과 — 한 행은 고객 1명**

| customer_id | transaction_count |
| --- | --- |
| A | 2 |
| B | 2 |
| C | 1 |
| D | 2 |

**바깥에서 transaction_count로 묶기**
- 1회 그룹: C → 1행 → 고객 1명
- 2회 그룹: A, B, D → 3행 → 고객 3명

| transaction_count | customer_count |
| --- | --- |
| 1 | 1 |
| 2 | 3 |

**그룹 하나가 최종 결과 한 행으로 나오지만, COUNT(\*)는 그룹 안에 들어간 행을 센다.** D만 1명이라고 세는 것이 아니라 같은 2회 그룹의 A·B·D를 함께 센다.
### 6. SQL에서 각 부분의 역할
```sql
SELECT
    transaction_count,           -- 어떤 거래 횟수 그룹인지
    COUNT(*) AS customer_count   -- 그 그룹에 들어간 고객 행 수
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count
    FROM bank_transactions
    GROUP BY customer_id
) AS customer_transactions
GROUP BY transaction_count
ORDER BY transaction_count ASC;
```
- 안쪽 GROUP BY customer_id: 같은 고객의 거래를 묶는다.
- 안쪽 COUNT(\*): 고객의 거래 행 수를 센다.
- AS customer_transactions: 중간 결과표에 이름을 붙인다.
- 바깥 GROUP BY transaction_count: 같은 거래 횟수의 고객을 묶는다.
- 바깥 COUNT(\*): 중간 결과의 고객 행 수를 센다.
조건문 때문에 COUNT의 기능이 바뀌는 것이 아니다. COUNT는 계속 행을 세고, 대상으로 삼는 표의 한 행 의미가 바뀐다.
### 7. 다음에 문제를 받으면 적을 네 줄
1. 원본 한 행 = ?
2. 최종 결과 한 행 = ?
3. 중간 표가 필요한가? 필요하다면 한 행 = ?
4. 각 단계에서 무엇을 기준으로 묶고 무엇을 셀까?
### 8. 답을 보지 않고 할 이해 점검 — 미실행
- [ ] 전체 거래를 유지해야 하는 문제에서 고액 거래 WHERE를 쓰면 무엇이 달라지는지 설명하기
- [ ] 조건부 COUNT에 ELSE 0을 넣으면 왜 잘못되는지 설명하기
- [ ] 안쪽 COUNT와 바깥 COUNT가 각각 무엇을 세는지 설명하기
- [ ] 가상 고객 A·B·D가 모두 2회 거래할 때 고객 수 3을 직접 설명하기
- [ ] P5의 안쪽 SELECT만 빈 화면에서 다시 작성하기
- [ ] 중간 표를 확인한 뒤 바깥 SELECT를 직접 추가하기
**추가 연습 질문 — 아직 답하지 않음:** 고객별 총 거래금액을 구한 뒤 10,000 이상인 고객과 미만인 고객이 각각 몇 명인지 구하려면, 직전에 필요한 중간 표에는 어떤 두 컬럼이 있어야 할까?


### 🧠 오늘의 핵심 정리·회고·다음 학습
## 오늘 혼자 할 수 있었던 것
관찰된 기록: 고객별 GROUP BY, COUNT·SUM·AVG와 ROUND 기본 집계, P5의 안쪽 고객별 거래 횟수 작성·실행.
사용자 자기평가: CASE WHEN은 다시 풀면 구현 가능. 답을 보지 않은 재풀이 결과는 아직 확인하지 않았다.
## 아직 도움이 필요한 것
문제 문장에서 WHERE·HAVING·CASE WHEN·서브쿼리 선택하기, 중간 표 설계, 안쪽·바깥 행 의미 구분, COUNT·SUM의 NULL 처리, 별칭·출력·정렬 점검.
## 답을 보지 않고 다시 풀 문제 1개
P5 — 거래 횟수별 고객 수. 안쪽 작성 → 실행 → 한 행의 의미 설명 → 바깥 집계 → 원본 건수 대조 순서로 다시 푼다.
## 다음 학습 방식
새 문법을 급하게 추가하지 않는다. CASE WHEN은 조건을 바꿔 재작성하고, 서브쿼리는 중간 표부터 단계별로 연습한다. 문제는 테이블 소개·스키마·문제·출력 예시·예시 설명 순서로 제시하고 정답은 먼저 주지 않는다.
## 오늘의 해결 상태

| 문제 | 상태 | 독립성·확인 범위 |
| --- | --- | --- |
| P1 | 검증 완료 | 기본 집계 직접 작성, AI 피드백으로 필터·별칭 수정. 161행 검토 |
| P2 | 제공 결과 범위 검증 완료 | AI 피드백으로 행 조건·집계 조건·정렬 수정. 전체 출력 건수 미확인 |
| P3 | 검증 완료 | 조건부 COUNT 힌트 후 직접 수정. 161행 검토 |
| P4 | 제공 결과 범위 검증 완료 | ELSE 0 피드백 후 수정. 최종 첨부 115행만 확인 |
| P5 | 원본 대조 검증 완료 | 안쪽 직접 작성, 바깥 틀·최종 코드 도움. 독립 재구현 미확인 |

실행 결과가 맞는 것과 혼자 설명·재구현할 수 있는 것은 분리한다.



