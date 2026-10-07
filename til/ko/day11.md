# Day 11 — 학습 원기록

[English](../en/day11.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### 🛒 Day11 — Olist 집계·조건부 COUNT·서브쿼리
# SQL 학습 기록 — Day 11
## 🛒 Olist SQL — GROUP BY·HAVING·조건부 집계와 서브쿼리
- 학습일: 2026-09-30
- 환경: MySQL 8.4

### 📚 문제 1\~3 — GROUP BY·HAVING·조건부 집계
📚 문제 1\~3 — GROUP BY·HAVING·조건부 집계
# Olist SQL Study (2026-09-30)
## 오늘 학습 목표
- `GROUP BY`, `HAVING`, `ORDER BY` 복습
- `COUNT(*)`와 `COUNT(DISTINCT ...)` 차이 복습
- `CASE WHEN`을 이용한 조건부 집계
- `SUM(CASE WHEN ...)`의 의미 이해
- 서브쿼리를 이용한 2단계 집계
- `주문 → 고객 → 주`처럼 데이터 단위가 바뀌는 구조 이해
- 완성 쿼리를 외우기보다 단계별 결과를 확인하며 쿼리 만들기
---
# 문제 1 — 2017년 주별 배송 완료 주문 수
## 문제
2017년에 주문된 상품 중 `delivered` 상태인 주문 수를 주(state)별로 계산한다.
배송 완료 주문이 1,000건 이상인 주만 출력한다.
정렬:
```plain text
delivered_order_count DESC
customer_state ASC
```
---
## 첫 시도
```sql
SELECT
    c.customer_state,
    COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = '2017'
  AND o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING delivered_order_count >= 1000;
```
## 수정 사항
### 1. 연도는 숫자로 비교
```sql
YEAR(o.order_purchase_timestamp) = 2017
```
`YEAR()`의 반환값은 숫자이므로 `'2017'`보다 `2017`이 적절하다.
### 2. ORDER BY 추가
ORDER BY가 없으면 결과 순서는 보장되지 않는다.
---
## 최종 쿼리
```sql
SELECT
    c.customer_state,
    COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2017
  AND o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING delivered_order_count >= 1000
ORDER BY
    delivered_order_count DESC,
    customer_state ASC;
```
## 실제 결과


| customer_state | delivered_order_count |
| --- | --- |
| SP | 17071 |
| RJ | 5968 |
| MG | 5240 |
| RS | 2591 |
| PR | 2192 |
| SC | 1653 |
| BA | 1527 |


## 핵심
```plain text
WHERE
→ 원본 행 필터

GROUP BY
→ state별 집계

HAVING
→ 집계 결과 필터

ORDER BY
→ 최종 출력 순서
```
---
# 문제 2 — 2018년 주별 주문 수와 실제 고객 수
## 문제
2018년 주문을 대상으로 주별:
```plain text
전체 주문 수
실제 고객 수
```
를 동시에 계산한다.
실제 고객은 `customer_unique_id` 기준이다.
실제 고객이 1,000명 이상인 주만 출력한다.
---
## 첫 시도
```sql
SELECT
    c.customer_state,
    COUNT(*) AS order_count,
    COUNT(customer_unique_id) AS customer_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(order_purchase_timestamp) = 2017
GROUP BY c.customer_state
HAVING customer_count >= 1000
ORDER BY
    customer_count DESC,
    customer_state ASC;
```
## 오류
### 1. 연도 오류
문제는 2018년인데:
```sql
YEAR(order_purchase_timestamp) = 2017
```
로 작성함.
### 2. 실제 고객 수 계산
```sql
COUNT(customer_unique_id)
```
는 중복을 제거하지 않는다.
따라서 주문 수와 고객 수가 똑같이 나왔다.
---
## 수정
```sql
COUNT(DISTINCT c.customer_unique_id)
```
을 사용한다.
---
## 최종 쿼리
```sql
SELECT
    c.customer_state,
    COUNT(*) AS order_count,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING customer_count >= 1000
ORDER BY
    customer_count DESC,
    customer_state ASC;
```
## 실제 결과


| customer_state | order_count | customer_count |
| --- | --- | --- |
| SP | 23871 | 23289 |
| RJ | 6571 | 6400 |
| MG | 6181 | 6042 |
| RS | 2780 | 2715 |
| PR | 2755 | 2698 |
| SC | 1906 | 1868 |
| BA | 1784 | 1741 |
| DF | 1213 | 1182 |
| ES | 1061 | 1039 |
| GO | 1056 | 1030 |


## 핵심
```sql
COUNT(*)
```
→ 현재 행 수
```sql
COUNT(DISTINCT customer_unique_id)
```
→ 중복 제거한 실제 고객 수
예:
```plain text
SP 주문 수 = 23,871
SP 실제 고객 수 = 23,289
```
같은 고객이 여러 번 주문했기 때문에 차이가 발생한다.
---
# 문제 3 — 주별 전체 주문 / 배송 완료 / 취소 주문 수
## 문제
2018년 주문을 대상으로 주별:
```plain text
전체 주문 수
배송 완료 주문 수
취소 주문 수
```
를 한 행에서 동시에 계산한다.
전체 주문 수가 1,000건 이상인 주만 출력한다.
---
## 첫 시도
```sql
SELECT
    c.customer_state,
    COUNT(*) AS total_order_count,
    COUNT(CASE WHEN order_status = 'delivered' END) AS delivered_count,
    COUNT(CASE WHEN order_status = 'canceled' END) AS canceled_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING canceled_count >= 1000
ORDER BY
    total_order_count DESC,
    customer_state ASC;
```
## 오류
### 1. HAVING 대상 오류
문제 조건은:
```plain text
전체 주문 수 >= 1000
```
인데:
```sql
HAVING canceled_count >= 1000
```
으로 작성했다.
정확한 조건은:
```sql
HAVING total_order_count >= 1000
```
### 2. CASE WHEN 문법
처음에는:
```sql
CASE WHEN 조건 END
```
형태로 작성했다.
조건을 만족할 때 반환할 값이 필요하다.
```sql
CASE
    WHEN 조건 THEN 1
END
```
---
## 최종 작성한 쿼리
```sql
SELECT
    c.customer_state,
    COUNT(*) AS total_order_count,
    COUNT(
        CASE
            WHEN o.order_status = 'delivered' THEN 1
        END
    ) AS delivered_count,
    COUNT(
        CASE
            WHEN o.order_status = 'canceled' THEN 1
        END
    ) AS canceled_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING total_order_count >= 1000
ORDER BY
    total_order_count DESC,
    customer_state ASC;
```
## 실행 관련 문제
SQL 논리는 완성했지만 사용자가 직접 입력한 한 줄 쿼리에는 일반 공백이 아닌 특수 공백이 섞이면서:
```plain text
ERROR 1064
```
가 발생했다.
따라서 오늘 기록에서는:
```plain text
쿼리 논리 완성 ✅
실제 최종 결과 검증 ❌
```
으로 남긴다.
실행 결과는 임의로 기록하지 않는다.
---


### 🧩 문제 4 — 주별 반복 구매 고객 수
# 문제 4 — 주별 반복 구매 고객 수
## 문제
전체 기간을 대상으로 실제 고객이 2번 이상 주문했다면 반복 구매 고객이라고 정의한다.
각 주별 반복 구매 고객 수를 계산한다.
20명 이상인 주만 출력한다.
---
## 사용자가 작성한 최종 쿼리
```sql
SELECT
    customer_state,
    SUM(
        CASE
            WHEN order_count >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customer_count
FROM (
    SELECT
        c.customer_state,
        c.customer_unique_id,
        COUNT(*) AS order_count
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_state,
        c.customer_unique_id
) AS customer_orders
GROUP BY customer_state
HAVING repeat_customer_count >= 20
ORDER BY
    repeat_customer_count DESC,
    customer_state ASC;
```
## 실제 결과


| customer_state | repeat_customer_count |
| --- | --- |
| SP | 1296 |
| RJ | 421 |
| MG | 338 |
| RS | 167 |
| PR | 145 |
| SC | 95 |
| BA | 93 |
| GO | 64 |
| DF | 62 |
| ES | 57 |
| PE | 33 |
| MT | 29 |
| PA | 24 |
| CE | 22 |


---
# 문제 4 구조 이해
## STEP 1 — 고객별 주문 횟수
```sql
SELECT
    c.customer_state,
    c.customer_unique_id,
    COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_state,
    c.customer_unique_id;
```
결과 형태:
```plain text
state | customer | order_count
------------------------------
SP    | A        | 1
SP    | B        | 3
SP    | C        | 2
RJ    | D        | 1
```
현재:
```plain text
한 행 = 실제 고객 1명
```
이다.
---
# 왜 서브쿼리에 `AS customer_orders`를 붙이는가?
```sql
FROM (
    SELECT ...
) AS customer_orders
```
괄호 안 SELECT 결과는 새로운 임시 테이블처럼 사용된다.
그 중간 결과에:
```plain text
customer_orders
```
라는 이름을 붙인 것이다.
즉:
```plain text
customer_orders
= 고객별 주문 횟수를 계산해 놓은 중간 결과표
```
이다.
`customer_orders`라는 이름 자체가 특별한 문법은 아니다.
다른 이름도 가능하다.
```sql
AS x
```
```sql
AS customer_summary
```
등도 가능하다.
---
# `SUM(CASE WHEN ...)` 이해
오늘 가장 헷갈렸던 부분:
```sql
SUM(
    CASE
        WHEN order_count >= 2 THEN 1
        ELSE 0
    END
)
```
예:
```plain text
customer | order_count
----------------------
A        | 1
B        | 3
C        | 2
D        | 1
```
CASE 적용:
```plain text
A → 0
B → 1
C → 1
D → 0
```
그리고:
```plain text
0 + 1 + 1 + 0
= 2
```
따라서:
```plain text
반복 구매 고객 = 2명
```
이다.
즉:
```sql
SUM(CASE WHEN 조건 THEN 1 ELSE 0 END)
```
은:
> 조건에 해당하는 행의 개수를 세는 패턴
이라고 이해한다.
---
# 문제 4 전체 구조
```plain text
orders
한 행 = 주문
      ↓
GROUP BY state + customer
      ↓
customer_orders
한 행 = 고객
      ↓
order_count >= 2
      ↓
YES → 1
NO  → 0
      ↓
SUM()
      ↓
주별 반복 구매 고객 수
```
---


### 🧩 문제 5 — 2018년 주별 반복 구매율
# 문제 5 — 2018년 주별 반복 구매 고객 비율
## 문제
2018년 주문을 대상으로 주별:
```plain text
실제 고객 수
반복 구매 고객 수
반복 구매율
```
을 계산한다.
반복 구매 고객:
```plain text
2018년에 2회 이상 주문한 실제 고객
```
반복 구매율:
```plain text
repeat_customers
---------------- × 100
 total_customers
```
전체 실제 고객이 1,000명 이상인 주만 출력한다.
---
## 사용자가 작성한 최종 쿼리
```sql
SELECT
    customer_state,
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN order_count >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        SUM(
            CASE
                WHEN order_count >= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS repeat_rate

FROM (

    SELECT
        c.customer_state,
        c.customer_unique_id,
        COUNT(*) AS order_count

    FROM orders o

    JOIN customers c
        ON c.customer_id = o.customer_id

    WHERE YEAR(o.order_purchase_timestamp) = 2018

    GROUP BY
        c.customer_state,
        c.customer_unique_id

) AS customer_order

GROUP BY customer_state

HAVING total_customers >= 1000

ORDER BY
    repeat_rate DESC,
    customer_state ASC;
```
## 실제 결과


| customer_state | total_customers | repeat_customers | repeat_rate |
| --- | --- | --- | --- |
| DF | 1182 | 30 | 2.54 |
| RJ | 6400 | 158 | 2.47 |
| GO | 1030 | 25 | 2.43 |
| SP | 23289 | 537 | 2.31 |
| BA | 1741 | 39 | 2.24 |
| RS | 2715 | 59 | 2.17 |
| MG | 6042 | 126 | 2.09 |
| PR | 2698 | 55 | 2.04 |
| ES | 1039 | 21 | 2.02 |
| SC | 1868 | 37 | 1.98 |


---
# 문제 5 구조 단계별 이해
## STEP 1 — 2018년 고객별 주문 횟수
```sql
SELECT
    c.customer_state,
    c.customer_unique_id,
    COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY
    c.customer_state,
    c.customer_unique_id;
```
목표:
```plain text
2018년에 고객 한 명이 몇 번 주문했는가?
```
현재 한 행:
```plain text
실제 고객 1명
```
---
## STEP 2 — 전체 고객 수
서브쿼리 결과가:
```plain text
고객 1명 = 1행
```
이므로:
```sql
COUNT(*) AS total_customers
```
를 사용한다.
중요:
```plain text
orders에서 COUNT(*)
→ 주문 수

customer_order에서 COUNT(*)
→ 고객 수
```
같은 `COUNT(*)`라도 현재 데이터의 한 행이 무엇인지에 따라 의미가 달라진다.
---
## STEP 3 — 반복 고객 수
```sql
SUM(
    CASE
        WHEN order_count >= 2 THEN 1
        ELSE 0
    END
) AS repeat_customers
```
뜻:
```plain text
2회 이상 구매 → 1
1회 구매 → 0
```
전부 더하면 반복 구매 고객 수가 된다.
---
## STEP 4 — 반복 구매율
```plain text
반복 고객 수
÷
전체 고객 수
×
100
```
SQL:
```sql
SUM(
    CASE
        WHEN order_count >= 2 THEN 1
        ELSE 0
    END
) / COUNT(*) * 100
```
소수점 둘째 자리까지:
```sql
ROUND(..., 2)
```
---
# 문제 5 전체 흐름
```plain text
[orders]

한 행 = 주문

        ↓

WHERE YEAR(...) = 2018

        ↓

GROUP BY
state + customer

        ↓

[customer_order]

한 행 = 실제 고객

        ↓

COUNT(*)
→ 전체 고객 수

SUM(CASE WHEN order_count >= 2 ...)
→ 반복 고객 수

        ↓

반복 고객 / 전체 고객 × 100

        ↓

[최종 결과]

한 행 = 주(state)
```
---
# 오늘 서브쿼리 핵심
서브쿼리는:
> 최종 결과를 만들기 전에 필요한 중간 결과표
이다.
오늘 문제에서는 원본이:
```plain text
한 행 = 주문
```
인데 최종적으로 고객을 분석해야 했다.
따라서 먼저:
```plain text
한 행 = 고객
```
으로 바꾸는 과정이 필요했다.
그 역할을 서브쿼리가 했다.
---
# 오늘 GROUP BY 구조
## 첫 번째 GROUP BY
```sql
GROUP BY
    customer_state,
    customer_unique_id
```
목적:
```plain text
고객 1명 = 1행
```
---
## 두 번째 GROUP BY
```sql
GROUP BY customer_state
```
목적:
```plain text
주 1개 = 1행
```
---
# 오늘 가장 중요한 구조
```plain text
주문 1행
↓
고객 1행
↓
주 1행
```
또는:
```plain text
orders
↓
1차 GROUP BY
↓
customer_order
↓
2차 GROUP BY
↓
최종 결과
```
---


### 🧠 오늘의 핵심 정리·다음 학습
# 오늘 주요 오류 패턴
## 1. 문제 조건을 정확하게 읽지 않음
P1:
```plain text
ORDER BY 누락
```
P2:
```plain text
2018년 문제인데 2017년 사용
```
P3:
```plain text
전체 주문 >= 1000인데
취소 주문 >= 1000으로 작성
```
문법보다 문제 조건을 놓치는 경우가 있었다.
---
## 2. COUNT와 DISTINCT
```sql
COUNT(customer_unique_id)
```
는 중복 제거가 아니다.
실제 고객 수:
```sql
COUNT(DISTINCT customer_unique_id)
```
---
## 3. CASE WHEN
기본 구조:
```sql
CASE
    WHEN 조건 THEN 값
    ELSE 값
END
```
조건에 맞는 행의 개수를 셀 때:
```sql
SUM(
    CASE
        WHEN 조건 THEN 1
        ELSE 0
    END
)
```
---
## 4. 서브쿼리 별칭
```sql
) AS customer_orders
```
는 서브쿼리 결과 전체에 붙이는 테이블 이름이다.
---
## 5. 특수 공백 문제
SQL 논리가 맞아도 복사하면서 일반 공백이 아닌 특수 공백이 들어가면:
```plain text
ERROR 1064
```
가 발생할 수 있다.
정상적인 쿼리가 이상한 위치에서 syntax error가 나면:
```plain text
에러 직전 공백 삭제
→ 직접 스페이스바 입력
```
도 확인한다.
---
# 오늘 문제별 핵심
## P1
```plain text
YEAR
GROUP BY
HAVING
ORDER BY
```
기본 집계 복습.
## P2
```plain text
COUNT(*)
vs
COUNT(DISTINCT ...)
```
주문 수와 실제 고객 수 구분.
## P3
```plain text
CASE WHEN
조건부 COUNT
```
한 행에서 여러 상태별 개수를 계산.
## P4
```plain text
고객별 주문 횟수
→ 반복 고객 여부
→ 주별 반복 고객 수
```
쉬운 2단계 집계.
## P5
```plain text
고객별 주문 횟수
→ 전체 고객
→ 반복 고객
→ 반복 구매율
```
2단계 집계 응용.
---
# 현재 이해가 필요한 부분
현재 완성 쿼리는 참고하면 작성할 수 있지만:
```plain text
왜 서브쿼리를 써야 하는지
왜 GROUP BY가 두 번 나오는지
왜 COUNT(*)가 어느 곳에서는 주문 수이고
다른 곳에서는 고객 수인지
SUM(CASE WHEN ...)이 왜 고객 수가 되는지
```
가 아직 완전히 자연스럽지는 않다.
따라서 다음 세션부터는 최종 쿼리를 바로 작성하지 않는다.
---
# 다음 학습 방식
서브쿼리 문제는 앞으로:
```plain text
STEP 1
안쪽 쿼리만 작성

STEP 2
실제 결과 확인

STEP 3
"현재 한 행이 무엇인가?" 설명

STEP 4
바깥 쿼리 작성

STEP 5
CASE WHEN 추가

STEP 6
최종 조건 / 비율 추가
```
순서로 푼다.
---
# 다음 세션 계획
다음 2\~3일은 Finance 데이터셋을 사용한다.
Olist에서 익힌 문법을 다른 도메인에서 다시 적용한다.
순서:
```plain text
GROUP BY / HAVING
→ COUNT / DISTINCT
→ CASE WHEN
→ 고객별 집계
→ 쉬운 서브쿼리
→ 2단계 집계
```
새로운 문법을 빠르게 추가하기보다는 기존 구조를 다른 데이터에서 반복한다.
---
# 오늘 최종 체크포인트
문제를 보면 SQL부터 작성하지 않는다.
먼저:
```plain text
1. 원본 한 행은 무엇인가?

2. 최종 결과 한 행은 무엇인가?

3. 원본에서 바로 계산할 수 있는가?

4. 중간 결과가 필요한가?

5. 중간 결과 한 행은 무엇인가?

6. 첫 번째 GROUP BY는 무엇인가?

7. 중간 결과에서 다시 무엇을 계산하는가?

8. 두 번째 GROUP BY가 필요한가?
```
를 판단한다.
오늘 가장 중요한 문장:
> **서브쿼리는 최종 결과를 계산하기 전에 필요한 중간 표를 만드는 방법이다.**
그리고:
> **COUNT(\*)의 의미는 함수 자체가 아니라 현재 한 행이 무엇을 뜻하는지에 따라 달라진다.**
