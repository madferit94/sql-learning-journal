# Day 09 — 학습 원기록

[English](../en/day09.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### 🛒 Day9 — Olist 고객·지역별 집계와 서브쿼리
# SQL 학습 기록 — Day 9
## 🛒 Olist SQL — 고객·지역별 집계와 서브쿼리
- 환경: MySQL 8.4
## 🎯 오늘의 학습 목표
- `orders`와 `customers` 테이블의 관계 이해
- 분석 중심 테이블과 JOIN 대상 테이블 구분
- `customer_id`와 `customer_unique_id`의 차이 이해
- `WHERE`와 `HAVING` 구분
- 여러 컬럼을 이용한 `GROUP BY`
- 서브쿼리를 이용한 2단계 집계
- 문제 문장에서 날짜 기준 컬럼을 정확하게 선택하기
---
## 📌 주요 컬럼


| English column | Korean meaning | table | actual role |
| --- | --- | --- | --- |
| `order_id` | 주문 ID | `orders` | 주문 1건 식별 |
| `customer_id` | 주문 단위 고객 ID | `orders` | `customers.customer_id`와 JOIN |
| `order_status` | 주문 상태 | `orders` | delivered 등 상태 필터 |
| `order_purchase_timestamp` | 주문 발생 일시 | `orders` | 주문 발생 연도 기준 |
| `order_delivered_customer_date` | 고객 배송 완료 일시 | `orders` | 실제 배송 완료 날짜 |
| `customer_id` | 주문 단위 고객 ID | `customers` | `orders`와 연결 |
| `customer_unique_id` | 실제 고객 고유 ID | `customers` | 동일 실제 고객 식별 |
| `customer_city` | 고객 도시 | `customers` | 도시별 집계 |
| `customer_state` | 고객 주(state) | `customers` | 주별 집계 |


---
# 문제 1 — 2018년 주별 주문 수
## 문제
2018년에 발생한 주문을 고객의 `customer_state`별로 집계하여 주문 수를 구한다.
정렬:
1. 주문 수 내림차순
2. `customer_state` 오름차순
## 첫 시도
```sql
SELECT c.customer_state,
       COUNT(*) o.order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_purchase_timestamp = 2018
GROUP BY c.customer_state
ORDER BY o.order_count DESC, c.customer_state ASC;
```
## 오류
### 1. COUNT alias 문법
잘못된 형태:
```sql
COUNT(*) o.order_count
```
`o`는 `orders` 테이블의 alias이므로 계산 결과 alias에 붙이지 않는다.
수정:
```sql
COUNT(*) AS order_count
```
### 2. 날짜 조건
잘못된 형태:
```sql
WHERE o.order_purchase_timestamp = 2018
```
`order_purchase_timestamp`는 DATETIME이므로 연도를 추출해야 한다.
```sql
WHERE YEAR(o.order_purchase_timestamp) = 2018
```
### 3. ORDER BY alias
잘못된 형태:
```sql
ORDER BY o.order_count
```
`order_count`는 SELECT에서 새로 만든 alias이므로:
```sql
ORDER BY order_count
```
로 사용한다.
## 최종 쿼리
```sql
SELECT c.customer_state,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
ORDER BY order_count DESC, c.customer_state ASC;
```
## 실제 결과


| customer_state | order_count |
| --- | --- |
| SP | 23871 |
| RJ | 6571 |
| MG | 6181 |
| RS | 2780 |
| PR | 2755 |
| SC | 1906 |
| BA | 1784 |
| DF | 1213 |
| ES | 1061 |
| GO | 1056 |


**27 rows IN SET (1.24 sec)**
## 핵심 개념
분석 중심은 주문이므로:
```sql
FROM orders
```
주 정보는 `customers`에 있으므로:
```sql
JOIN customers
```
최종 한 행은 주 하나이므로:
```sql
GROUP BY customer_state
```
---
# 문제 2 — 실제 고객별 주문 횟수
## 문제
전체 기간 동안 실제 고객별 주문 횟수를 구한다.
동일한 실제 고객은:
```sql
customer_unique_id
```
로 판단한다.
2번 이상 주문한 고객만 출력한다.
## 첫 시도
```sql
SELECT c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_unique_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC, customer_unique_id ASC;
```
결과:
```plain text
Empty SET
```
## 첫 번째 오류 — JOIN key
잘못된 연결:
```sql
c.customer_unique_id = o.customer_id
```
의미가 다른 컬럼을 연결했다.
올바른 JOIN:
```sql
c.customer_id = o.customer_id
```
---
## 두 번째 시도
```sql
SELECT c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY o.customer_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC, customer_unique_id ASC;
```
결과:
```plain text
Empty SET
```
## 두 번째 오류 — GROUP BY 기준
`customer_id`는 주문 단위 고객 ID이므로 주문마다 달라질 수 있다.
문제에서 원하는 것은:
```plain text
실제 고객별
```
이므로:
```sql
GROUP BY c.customer_unique_id
```
가 필요하다.
## 최종 쿼리
```sql
SELECT c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC, customer_unique_id ASC;
```
## 실제 결과 상위


| customer_unique_id | order_count |
| --- | --- |
| 8d50f5eadf50201ccdcedfb9e2ac8455 | 17 |
| 3e43e6105506432c953e165fb2acf44c | 9 |
| 1b6c7548a2a1f9037c1fd3ddfed95f33 | 7 |
| 6469f99c1f9dfae7733b25662e7f1782 | 7 |
| ca77025e7201e3b30c44b472ff346268 | 7 |


## 핵심 개념
JOIN 기준과 GROUP BY 기준은 다를 수 있다.
```plain text
JOIN
orders.customer_id
=
customers.customer_id
```
하지만 실제 고객별 집계는:
```sql
GROUP BY customers.customer_unique_id
```
---
# 문제 3 — 2018년 주별 배송 완료 주문 수
## 문제
2018년에 발생한 주문 중 `delivered` 상태인 주문의 수를 주별로 구한다.
배송 완료 주문이 500건 이상인 주만 출력한다.
## 첫 시도
```sql
SELECT c.customer_state,
       COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND YEAR(order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING COUNT(*) >= 500
ORDER BY delivered_order_count DESC, customer_state ASC;
```
## 결과
첫 시도 정답.


| customer_state | delivered_order_count |
| --- | --- |
| SP | 23335 |
| RJ | 6342 |
| MG | 6079 |
| RS | 2737 |
| PR | 2711 |
| SC | 1884 |
| BA | 1726 |
| DF | 1193 |
| ES | 1047 |
| GO | 1033 |
| PE | 852 |
| CE | 633 |


**12 rows IN SET (0.19 sec)**
## 핵심 개념
원본 주문 행을 필터링:
```sql
WHERE
```
집계된 주문 수를 필터링:
```sql
HAVING
```
따라서:
```sql
WHERE order_status = 'delivered'
```
와
```sql
HAVING COUNT(*) >= 500
```
의 역할이 다르다.
---
# 문제 4 — 주·도시별 배송 완료 주문 수
## 문제
2018년에 발생한 `delivered` 주문을 주와 도시별로 집계한다.
300건 이상인 주·도시 조합만 출력한다.
## 첫 시도
```sql
SELECT c.customer_state,
       c.customer_city,
       COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE YEAR(order_delivered_customer_date) = 2018
GROUP BY customer_state, customer_city
HAVING delivered_order_count >= 300
ORDER BY delivered_order_count DESC,
         customer_state ASC,
         customer_city ASC;
```
## 오류
GROUP BY는 정확했다.
```sql
GROUP BY customer_state, customer_city
```
하지만 문제는:
```plain text
2018년에 발생한 주문
```
이었다.
첫 시도는:
```sql
YEAR(order_delivered_customer_date) = 2018
```
로 작성하여:
```plain text
2018년에 배송된 주문
```
을 찾았다.
두 조건은 다르다.
---
## 두 번째 시도
```sql
WHERE YEAR(order_delivered_customer_date) = 2018
  AND o.order_status = 'delivered'
```
`delivered` 조건은 추가했지만 날짜 기준 컬럼은 여전히 배송 완료일이었다.
---
## 최종 쿼리
```sql
SELECT c.customer_state,
       c.customer_city,
       COUNT(*) AS delivered_order_count
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE YEAR(order_purchase_timestamp) = 2018
  AND o.order_status = 'delivered'
GROUP BY customer_state, customer_city
HAVING delivered_order_count >= 300
ORDER BY delivered_order_count DESC,
         customer_state ASC,
         customer_city ASC;
```
## 실제 결과


| customer_state | customer_city | delivered_order_count |
| --- | --- | --- |
| SP | sao paulo | 8891 |
| RJ | rio de janeiro | 3376 |
| MG | belo horizonte | 1527 |
| DF | brasilia | 1193 |
| PR | curitiba | 851 |
| SP | campinas | 801 |
| SP | guarulhos | 673 |
| RS | porto alegre | 665 |
| BA | salvador | 649 |
| SP | sao bernardo do campo | 526 |


**21 rows IN SET (0.20 sec)**
## 핵심 개념 1 — GROUP BY가 두 개인 이유
최종 한 행이:
```plain text
state + city
```
조합이기 때문이다.
예:
```plain text
SP + sao paulo
SP + campinas
RJ + rio de janeiro
```
따라서:
```sql
GROUP BY customer_state, customer_city
```
이다.
## 핵심 개념 2 — 날짜 컬럼 선택
문제의 표현을 정확하게 읽는다.
```plain text
주문 발생
→ order_purchase_timestamp

배송 완료
→ order_delivered_customer_date
```
문법이 맞아도 기준 컬럼이 다르면 다른 분석이 된다.
---
# 문제 5 — 주별 반복 구매 고객 수
## 문제
전체 기간 동안 2번 이상 주문한 실제 고객 수를 주별로 구한다.
동일한 실제 고객은:
```sql
customer_unique_id
```
가 같으면 같은 고객으로 판단한다.
## 첫 시도
```sql
SELECT c.customer_state,
       SUM(c.customer_unique_id) AS repeat_customer_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE c.customer_unique_id >= 2
GROUP BY customer_state
ORDER BY repeat_customer_count DESC, customer_state ASC;
```
## 오류 1 — ID를 SUM()
```sql
customer_unique_id
```
는 문자열 ID이다.
따라서:
```sql
SUM(customer_unique_id)
```
는 의미가 없다.
MySQL이 문자열을 숫자로 변환하려 하면서:
```plain text
0
7905942697
1.7976931348623157e308
```
같은 비정상 값이 발생했다.
실행 결과:
**27 rows IN SET, 65535 warnings**
## 오류 2 — `customer_unique_id >= 2`
문제의:
```plain text
2번 이상 주문
```
은 ID 값이 2 이상이라는 뜻이 아니다.
고객별:
```sql
COUNT(*) >= 2
```
라는 의미이다.
---
## 1단계 — 실제 고객별 주문 횟수
첫 시도:
```sql
SELECT c.customer_state,
       c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.order_id
GROUP BY c.customer_state,
         c.customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC,
         customer_state ASC;
```
### 오류
잘못된 JOIN:
```sql
c.customer_id = o.order_id
```
고객 ID와 주문 ID를 연결했다.
수정:
```sql
c.customer_id = o.customer_id
```
---
## 올바른 1단계
```sql
SELECT c.customer_state,
       c.customer_unique_id,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY c.customer_state,
         c.customer_unique_id
HAVING COUNT(*) >= 2;
```
이 결과의 한 행은:
```plain text
주 + 반복 고객 한 명 + 그 고객의 주문 횟수
```
이다.
예:
```plain text
SP | 고객A | 17
SP | 고객B | 9
MG | 고객C | 7
```
---
## 2단계 — 주별 반복 고객 수
1단계 결과에서 한 행이 이미 반복 고객 한 명이다.
따라서 그 결과를 서브쿼리로 만든 뒤:
```sql
COUNT(*)
```
하면 주별 반복 고객 수를 구할 수 있다.
## 최종 쿼리
```sql
SELECT customer_state,
       COUNT(*) AS repeat_customer_count
FROM (
    SELECT c.customer_state,
           c.customer_unique_id,
           COUNT(*) AS order_count
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_state,
             c.customer_unique_id
    HAVING COUNT(*) >= 2
) AS repeat_customers
GROUP BY customer_state
ORDER BY repeat_customer_count DESC,
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
| MS | 18 |
| MA | 17 |
| PB | 13 |
| AL | 12 |
| PI | 11 |
| RN | 11 |
| RO | 10 |
| SE | 8 |
| TO | 7 |
| AC | 4 |
| AM | 3 |
| AP | 1 |
| RR | 1 |


**27 rows IN SET (0.50 sec)**
## 핵심 개념 — 집계 결과를 다시 집계
이번 문제는 한 번의 GROUP BY만으로 생각하기 어려웠다.
### 안쪽 쿼리
```plain text
한 행 = state + 실제 고객
```
따라서:
```sql
GROUP BY customer_state, customer_unique_id
```
그리고:
```sql
HAVING COUNT(*) >= 2
```
로 반복 고객만 남긴다.
### 바깥 쿼리
안쪽 결과의 한 행은 이미:
```plain text
반복 고객 1명
```
을 의미한다.
그러므로:
```sql
GROUP BY customer_state
```
후:
```sql
COUNT(*)
```
하면 주별 반복 고객 수가 된다.
---
# 🔍 오늘의 주요 오류 패턴
## 1. JOIN은 컬럼 이름보다 의미를 먼저 본다
잘못된 연결:
```sql
customer_unique_id = customer_id
customer_id = order_id
```
JOIN 전에 반드시 확인:
```plain text
왼쪽 컬럼은 무엇을 의미하는가?
오른쪽 컬럼은 무엇을 의미하는가?
둘이 같은 종류의 ID인가?
```
Olist의 기본 연결:
```sql
orders.customer_id = customers.customer_id
```
---
## 2. `customer_id`와 `customer_unique_id` 구분
```plain text
customer_id
→ 주문 단위 고객 ID
→ orders와 customers 연결용

customer_unique_id
→ 실제 고객 식별
→ 고객 단위 분석용
```
즉:
```plain text
JOIN → customer_id
고객별 GROUP BY → customer_unique_id
```
---
## 3. GROUP BY 개수는 외우지 않는다
질문:
```plain text
최종 결과 한 행이 무엇을 의미하는가?
```
P1:
```plain text
한 행 = state
→ GROUP BY state
```
P4:
```plain text
한 행 = state + city
→ GROUP BY state, city
```
P5 안쪽:
```plain text
한 행 = state + 실제 고객
→ GROUP BY state, customer_unique_id
```
P5 바깥:
```plain text
한 행 = state
→ GROUP BY state
```
---
## 4. WHERE와 HAVING
```plain text
원본 행의 조건
→ WHERE

집계한 결과의 조건
→ HAVING
```
예:
```sql
WHERE order_status = 'delivered'
```
```sql
HAVING COUNT(*) >= 500
```
---
## 5. 날짜 컬럼의 의미 확인
문제 문장에서:
```plain text
2018년에 주문
```
이면:
```sql
order_purchase_timestamp
```
을 사용한다.
```plain text
2018년에 배송 완료
```
라면:
```sql
order_delivered_customer_date
```
를 사용한다.
날짜 함수 자체보다 **어떤 날짜 컬럼을 써야 하는지 판단하는 것**이 먼저다.
---
## 6. 문자열 ID에는 SUM을 사용하지 않는다
```sql
SUM(customer_unique_id)
```
는 의미가 없다.
ID를 대상으로 보통 생각할 수 있는 것은:
```sql
COUNT(*)
COUNT(customer_unique_id)
COUNT(DISTINCT customer_unique_id)
```
등이다.
`SUM()`은 주문금액, 수량, 득점처럼 숫자 값 자체를 합산할 때 사용한다.
---
# 📝 오늘의 회고
오늘 가장 중요한 진전은 단순 SQL 문법보다는 문제 구조를 해석하는 과정이었다.
특히 P1\~P4에서는:
```plain text
중심 테이블
→ 필요한 추가 테이블
→ JOIN key
→ 최종 결과 한 행의 단위
```
를 구분하기 시작했다.
P5에서는 처음으로:
```plain text
고객별 집계
→ 조건 적용
→ 집계 결과를 서브쿼리화
→ 주별 재집계
```
라는 2단계 집계 구조를 경험했다.
현재 반복해서 주의할 부분은:
```plain text
1. JOIN key의 의미
2. customer_id vs customer_unique_id
3. 문제 문장의 날짜 기준
4. 최종 한 행의 단위에 따른 GROUP BY
```
이다.
---
# ➡️ 다음 학습 포인트
다음 Olist 세션에서는 새로운 테이블을 추가해:
```plain text
orders
customers
order_items
```
처럼 3개 테이블 관계로 확장하는 것이 적절하다.
학습 방향:
```plain text
1. 새 테이블 스키마 확인
2. orders ↔ order_items 관계 이해
3. 주문별 상품 수
4. 주문별 금액 집계
5. 1:N JOIN에서 행이 늘어나는 이유
6. COUNT(*)와 COUNT(DISTINCT order_id)의 차이
```
특히 다음 단계에서는:
```plain text
JOIN하면 왜 행 수가 늘어나는가?
```
를 이해하는 것이 중요하다.

---
