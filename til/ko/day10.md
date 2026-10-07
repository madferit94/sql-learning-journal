# Day 10 — 학습 원기록

[English](../en/day10.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### 🛒 Day10 — 날짜·월별 집계와 반복 구매율
# SQL 학습 기록 — Day 10
## 🛒 Olist SQL — 날짜·고객 집계와 반복 구매율
- 환경: MySQL 8.4

### 📚 문제 1\~4 — 날짜·고객·주문상태 집계
## 학습 목표
- 날짜 데이터를 연도/월 단위로 필터링하고 집계하기
- `COUNT(*)`와 `COUNT(DISTINCT ...)`의 차이 이해하기
- 실제 고객과 주문 행을 구분하기
- 최종 결과의 한 행 기준에 따라 `GROUP BY` 결정하기
- `IN`을 이용한 다중 조건 필터링
- `MIN()`, `MAX()`를 이용한 첫 주문/마지막 주문 계산
- `CASE WHEN`을 이용한 조건부 집계
- 고객 단위 집계 → 주 단위 재집계 이해하기
- 서브쿼리가 필요한 경우와 필요하지 않은 경우 구분하기
- 문제를 SQL로 바로 옮기기 전에 데이터의 **한 행 단위**를 먼저 판단하기
---
# 사용 테이블
## orders


| column name | type | nullable |
| --- | --- | --- |
| `order_id` | varchar(32) | false |
| `customer_id` | varchar(32) | false |
| `order_status` | varchar(20) | false |
| `order_purchase_timestamp` | datetime | false |
| `order_approved_at` | datetime | true |
| `order_delivered_carrier_date` | datetime | true |
| `order_delivered_customer_date` | datetime | true |
| `order_estimated_delivery_date` | datetime | false |


## customers


| column name | type | nullable |
| --- | --- | --- |
| `customer_id` | varchar(32) | false |
| `customer_unique_id` | varchar(32) | false |
| `customer_zip_code_prefix` | varchar(5) | true |
| `customer_city` | varchar(100) | true |
| `customer_state` | char(2) | true |


### JOIN 기준
```sql
orders.customer_id = customers.customer_id
```
`customer_id`는 주문과 고객 정보를 연결할 때 사용한다.
반면 실제 고객을 구분할 때는:
```sql
customer_unique_id
```
를 사용한다.
---
# 문제 1 — 2017년 월별 배송 완료 주문 수
## 문제
2017년에 발생한 주문 중 `order_status = 'delivered'`인 주문의 수를 월별로 구한다.
월은 `YYYY-MM` 형식으로 출력하고 월 오름차순으로 정렬한다.
---
## 첫 시도
```sql
SELECT
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*) AS delivered_order_count
FROM orders
WHERE MONTH(order_purchase_timestamp) = 2017
  AND order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month DESC;
```
## 오류
### 1. `MONTH()`와 `YEAR()` 혼동
```sql
MONTH(order_purchase_timestamp)
```
은 `1~12`를 반환한다.
따라서:
```sql
MONTH(order_purchase_timestamp) = 2017
```
은 올바른 연도 필터가 아니다.
연도를 추출할 때는:
```sql
YEAR(order_purchase_timestamp)
```
을 사용해야 한다.
### 2. 출력 형식
문제에서는:
```plain text
2017-01
2017-02
...
```
형식을 요구했다.
따라서:
```sql
DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
```
을 사용한다.
### 3. 정렬 방향
문제는 월 오름차순이므로:
```sql
ORDER BY order_month ASC
```
이어야 한다.
---
## 두 번째 시도
```sql
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS delivered_order_count
FROM orders
WHERE DATE_FORMAT(order_purchase_timestamp, '%Y-%m') = 2017
  AND order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month ASC;
```
결과는 나왔지만 많은 warning이 발생했다.
### 원인
```sql
DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
```
의 결과는:
```plain text
'2017-01'
'2017-02'
```
같은 문자열이다.
그런데 이것을 숫자:
```plain text
2017
```
과 비교하면서 MySQL의 암묵적 형변환이 발생했다.
---
## 최종 쿼리
```sql
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS delivered_order_count
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2017
  AND order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month ASC;
```
## 실제 실행 결과


| order_month | delivered_order_count |
| --- | --- |
| 2017-01 | 750 |
| 2017-02 | 1653 |
| 2017-03 | 2546 |
| 2017-04 | 2303 |
| 2017-05 | 3546 |
| 2017-06 | 3135 |
| 2017-07 | 3872 |
| 2017-08 | 4193 |
| 2017-09 | 4150 |
| 2017-10 | 4478 |
| 2017-11 | 7289 |
| 2017-12 | 5513 |


## 핵심
```sql
YEAR(date_column)
```
→ 연도 필터
```sql
MONTH(date_column)
```
→ 월 숫자 추출
```sql
DATE_FORMAT(date_column, '%Y-%m')
```
→ 원하는 월 출력 형식 만들기
---
# 문제 2 — 2018년 주별 실제 고객 수
## 문제
2018년에 주문한 실제 고객 수를 주(state)별로 구한다.
같은 실제 고객이 여러 번 주문했더라도 한 명으로만 계산한다.
실제 고객이 500명 이상인 주만 출력한다.
---
## 첫 시도
```sql
SELECT
    c.customer_state,
    COUNT(*) AS customer_count
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
WHERE YEAR(order_purchase_timestamp) = 2018
GROUP BY customer_unique_id
HAVING customer_count >= 500
ORDER BY customer_count DESC, customer_count ASC;
```
## 오류
### 1. GROUP BY 기준 오류
최종 결과는:
```plain text
주 하나 = 결과 한 행
```
이다.
따라서:
```sql
GROUP BY customer_state
```
이어야 한다.
### 2. 고객 수가 아닌 행 수를 셈
```sql
COUNT(*)
```
은 주문 행의 수를 센다.
같은 고객이 여러 번 주문했다면 여러 번 포함된다.
### 3. ORDER BY 오류
```sql
ORDER BY customer_count DESC,
         customer_count ASC
```
처럼 동일한 컬럼을 서로 반대 방향으로 두 번 정렬했다.
문제 조건은:
```plain text
customer_count DESC
customer_state ASC
```
였다.
---
## 두 번째 시도
```sql
COUNT(customer_unique_id)
```
를 사용했다.
하지만 이것도 `customer_unique_id`가 NULL이 아닌 행의 개수를 세는 것이므로 중복 고객이 제거되지 않는다.
실제 결과에서:
```plain text
SP = 23871
```
로 나왔고, 이는 주문 수와 동일한 값이었다.
---
## 핵심 수정
```sql
COUNT(DISTINCT customer_unique_id)
```
를 사용하면 동일한 실제 고객을 한 번만 센다.
---
## 최종 쿼리
```sql
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
GROUP BY c.customer_state
HAVING customer_count >= 500
ORDER BY customer_count DESC,
         c.customer_state ASC;
```
## 실제 실행 결과


| customer_state | customer_count |
| --- | --- |
| SP | 23289 |
| RJ | 6400 |
| MG | 6042 |
| RS | 2715 |
| PR | 2698 |
| SC | 1868 |
| BA | 1741 |
| DF | 1182 |
| ES | 1039 |
| GO | 1030 |
| PE | 862 |
| CE | 661 |


## 핵심
```sql
COUNT(*)
```
→ 행 개수
```sql
COUNT(customer_unique_id)
```
→ NULL이 아닌 값의 개수
```sql
COUNT(DISTINCT customer_unique_id)
```
→ 중복을 제거한 실제 고객 수
---
# 문제 3 — 2018년 주·주문상태별 주문 수
## 문제
2018년에 발생한 주문 중:
```plain text
delivered
canceled
```
상태인 주문만 대상으로 한다.
고객의 주와 주문 상태별 주문 수를 구하고, 주문 수가 50건 이상인 조합만 출력한다.
---
## 첫 시도
```sql
SELECT
    c.customer_state,
    o.order_status
FROM (
    SELECT
        order_status,
        order_purchase_timestamp
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    WHERE YEAR(order_purchase_timestamp) = 2018
) AS order_count
GROUP BY order_status
HAVING order_count >= 50
ORDER BY customer_state ASC,
         order_count DESC;
```
## 오류
이 문제에서는 서브쿼리가 필요하지 않았다.
또한:
- `COUNT(*)`이 없음
- `customer_state`가 서브쿼리 결과에 없음
- 서브쿼리 밖에서 `c`, `o`를 사용할 수 없음
- 최종 한 행은 `state + status`인데 `status`만 GROUP BY
- `delivered`, `canceled` 조건이 없음
---
## 두 번째 시도
```sql
SELECT
    c.customer_state,
    o.order_status,
    COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(order_purchase_timestamp) = 2018
GROUP BY c.customer_state,
         o.order_status
HAVING order_count >= 50
ORDER BY customer_state ASC,
         order_count DESC;
```
구조는 거의 맞았지만:
```plain text
shipped
unavailable
invoiced
```
등의 상태도 결과에 포함됐다.
---
## 수정
여러 특정 값을 필터링하기 위해:
```sql
IN ('delivered', 'canceled')
```
을 사용한다.
---
## 최종 쿼리
```sql
SELECT
    c.customer_state,
    o.order_status,
    COUNT(*) AS order_count
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE YEAR(o.order_purchase_timestamp) = 2018
  AND o.order_status IN ('delivered', 'canceled')
GROUP BY
    c.customer_state,
    o.order_status
HAVING order_count >= 50
ORDER BY
    c.customer_state ASC,
    order_count DESC;
```
## 실제 실행 결과


| customer_state | order_status | order_count |
| --- | --- | --- |
| AL | delivered | 198 |
| AM | delivered | 72 |
| BA | delivered | 1726 |
| CE | delivered | 633 |
| DF | delivered | 1193 |
| ES | delivered | 1047 |
| GO | delivered | 1033 |
| MA | delivered | 346 |
| MG | delivered | 6079 |
| MS | delivered | 411 |
| MT | delivered | 476 |
| PA | delivered | 453 |
| PB | delivered | 269 |
| PE | delivered | 852 |
| PI | delivered | 258 |
| PR | delivered | 2711 |
| RJ | delivered | 6342 |
| RN | delivered | 241 |
| RO | delivered | 109 |
| RS | delivered | 2737 |
| SC | delivered | 1884 |
| SE | delivered | 146 |
| SP | delivered | 23335 |
| SP | canceled | 188 |
| TO | delivered | 144 |


## 핵심
최종 한 행이:
```plain text
customer_state + order_status
```
조합이다.
따라서:
```sql
GROUP BY
    customer_state,
    order_status
```
를 사용한다.
### GROUP BY를 고를 때
몇 개의 컬럼을 넣어야 하는지를 먼저 생각하지 않는다.
항상:
> **최종 결과 한 행을 무엇이 결정하는가?**
를 생각한다.
---
# 문제 4 — 3번 이상 주문한 고객의 첫 주문과 마지막 주문
## 문제
전체 기간을 대상으로 실제 고객별:
- 주문 횟수
- 첫 주문 일시
- 마지막 주문 일시
를 계산한다.
3번 이상 주문한 고객만 출력한다.
---
## 최종 쿼리
```sql
SELECT
    c.customer_unique_id,
    COUNT(*) AS order_count,
    MIN(o.order_purchase_timestamp) AS first_order_date,
    MAX(o.order_purchase_timestamp) AS last_order_date
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING order_count >= 3
ORDER BY
    order_count DESC,
    c.customer_unique_id ASC;
```
## 실제 실행 결과 일부


| customer_unique_id | order_count | first_order_date | last_order_date |
| --- | --- | --- | --- |
| 8d50f5eadf50201ccdcedfb9e2ac8455 | 17 | 2017-05-15 23:30:03 | 2018-08-20 19:14:26 |
| 3e43e6105506432c953e165fb2acf44c | 9 | 2017-09-18 18:53:15 | 2018-02-27 18:36:39 |
| 1b6c7548a2a1f9037c1fd3ddfed95f33 | 7 |  |  |
| 6469f99c1f9dfae7733b25662e7f1782 | 7 |  |  |
| ca77025e7201e3b30c44b472ff346268 | 7 |  |  |
| ... |  |  |  |


총:
**252 rows in set**
실제 실행 결과에서도 주문 횟수 17회 고객부터 주문 횟수 기준으로 정상 정렬됐다. 
전체 결과는 252행이었다. 
## 핵심
하나의 `GROUP BY` 안에서 여러 집계함수를 동시에 사용할 수 있다.
```sql
COUNT(*)
MIN(date)
MAX(date)
```
이 문제는 고객별 결과를 만든 뒤 다시 다른 단위로 재집계할 필요가 없다.
따라서 서브쿼리가 필요하지 않았다.
---


### 🧩 문제 5 — 주별 반복 구매 고객 비율
## 문제
전체 기간을 대상으로 각 주(state)의 다음 값을 구한다.
- 전체 실제 고객 수
- 2번 이상 주문한 반복 구매 고객 수
- 반복 구매 고객 비율
실제 고객은 `customer_unique_id`를 기준으로 판단한다.
반복 구매 고객:
```plain text
order_count >= 2
```
반복 구매율:
```plain text
repeat_rate
= repeat_customers / total_customers × 100
```
전체 실제 고객이 500명 이상인 주만 출력하고,
```plain text
repeat_rate DESC
customer_state ASC
```
순으로 정렬한다.
---
# 0. 이 문제가 어려운 이유
이 문제는 원본 데이터를 바로 주별로 집계하는 문제가 아니다.
데이터의 한 행 기준이 중간에 한 번 바뀐다.
```plain text
[원본]
주문 1건 = 1행

        ↓ 1차 GROUP BY

[중간 결과]
실제 고객 1명 = 1행

        ↓ 2차 GROUP BY

[최종 결과]
주(state) 1개 = 1행
```
즉 집계를 한 번 하고 끝나는 것이 아니라:
```plain text
주문
→ 고객
→ 주
```
순서로 두 번 집계해야 한다.
---
# 1. 먼저 원본 데이터를 생각하기
`orders`와 `customers`를 JOIN하면 개념적으로 다음과 같은 데이터가 있다고 생각할 수 있다.
```plain text
state | customer_unique_id | order_id
--------------------------------------
SP    | A                  | order1
SP    | A                  | order2
SP    | B                  | order3
SP    | C                  | order4
SP    | C                  | order5
SP    | C                  | order6
RJ    | D                  | order7
RJ    | E                  | order8
RJ    | E                  | order9
```
현재 한 행은:
```plain text
주문 1건
```
이다.
여기서 바로:
```sql
GROUP BY customer_state
```
를 하면 구할 수 있는 것은 주별 **주문 수**다.
하지만 문제는 주문 수가 아니라:
```plain text
고객이 몇 명인가?
그중 반복 구매 고객이 몇 명인가?
```
를 묻는다.
따라서 먼저 주문 데이터를 **고객 단위**로 바꿔야 한다.
---
# 2. 1단계 — 실제 고객별 주문 횟수 만들기
## 목표
먼저 다음 표를 만든다.
```plain text
state | customer | order_count
------------------------------
SP    | A        | 2
SP    | B        | 1
SP    | C        | 3
RJ    | D        | 1
RJ    | E        | 2
```
이제 한 행의 의미는:
```plain text
실제 고객 1명
```
이다.
## SQL
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
## 왜 GROUP BY가 두 컬럼인가?
한 행을 결정하는 기준이:
```plain text
주 + 실제 고객
```
이기 때문이다.
즉:
```sql
GROUP BY
    c.customer_state,
    c.customer_unique_id
```
를 사용한다.
---
# 3. 1단계 결과를 다시 읽기
예를 들어 1단계 결과가 다음과 같다고 하자.
```plain text
state | customer | order_count
------------------------------
MG    | A        | 1
MG    | B        | 2
MG    | C        | 4
MG    | D        | 1
MG    | E        | 3
```
전체 고객은:
```plain text
A
B
C
D
E

→ 5명
```
따라서:
```plain text
total_customers = 5
```
반복 구매 조건은:
```plain text
order_count >= 2
```
이므로:
```plain text
A = 1회 → X
B = 2회 → O
C = 4회 → O
D = 1회 → X
E = 3회 → O
```
따라서:
```plain text
repeat_customers = 3
```
반복 구매율은:
```plain text
3 / 5 × 100
= 60%
```
최종적으로:
```plain text
MG | 5 | 3 | 60.00
```
가 된다.
---
# 4. 2단계 — 주별 전체 고객 수만 먼저 계산하기
1단계 결과에서는 이미:
```plain text
고객 1명 = 1행
```
이다.
따라서 이제 주별로 묶은 뒤 행 수를 세면 고객 수가 된다.
```sql
SELECT
    customer_state,
    COUNT(*) AS total_customers
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
GROUP BY customer_state;
```
## 중요한 점
여기의:
```sql
COUNT(*)
```
는 원본 `orders`의 행을 세는 것이 아니다.
서브쿼리가 이미:
```plain text
고객 1명 = 1행
```
으로 바뀐 상태이므로:
```sql
COUNT(*)
```
는 이제 **고객 수**가 된다.
---
# 5. 3단계 — 반복 구매 고객 수 추가하기
이제 고객별 `order_count`를 보고:
```plain text
2회 이상 → 1
1회      → 0
```
으로 바꾼다.
SQL에서는 `CASE WHEN`을 사용한다.
```sql
CASE
    WHEN order_count >= 2 THEN 1
    ELSE 0
END
```
예:
```plain text
customer | order_count | CASE 결과
-----------------------------------
A        | 1           | 0
B        | 2           | 1
C        | 4           | 1
D        | 1           | 0
E        | 3           | 1
```
이 값을 모두 더하면:
```plain text
0 + 1 + 1 + 0 + 1
= 3
```
즉 반복 구매 고객은 3명이다.
따라서:
```sql
SUM(
    CASE
        WHEN order_count >= 2 THEN 1
        ELSE 0
    END
) AS repeat_customers
```
를 사용한다.
---
# 6. 전체 고객 + 반복 고객까지 계산한 버전
```sql
SELECT
    customer_state,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN order_count >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customers
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
GROUP BY customer_state;
```
실제 실행 결과 일부:


| customer_state | total_customers | repeat_customers |
| --- | --- | --- |
| AC | 77 | 4 |
| AL | 401 | 12 |
| AM | 143 | 3 |
| BA | 3277 | 93 |
| MG | 11259 | 338 |
| PR | 4882 | 145 |
| RJ | 12384 | 421 |
| RS | 5277 | 167 |
| SC | 3534 | 95 |
| SP | 40302 | 1296 |


---
# 7. 4단계 — 반복 구매율 계산하기
공식은:
```plain text
repeat_customers
---------------- × 100
 total_customers
```
이다.
현재 SQL 표현으로 바꾸면:
```plain text
repeat_customers
=
SUM(
    CASE
        WHEN order_count >= 2 THEN 1
        ELSE 0
    END
)
```
그리고:
```plain text
total_customers
=
COUNT(*)
```
따라서:
```sql
SUM(
    CASE
        WHEN order_count >= 2 THEN 1
        ELSE 0
    END
) / COUNT(*) * 100
```
이 된다.
소수점 둘째 자리까지 표시해야 하므로:
```sql
ROUND(
    SUM(
        CASE
            WHEN order_count >= 2 THEN 1
            ELSE 0
        END
    ) / COUNT(*) * 100,
    2
) AS repeat_rate
```
를 사용한다.
---
# 8. 반복 구매율까지 계산한 버전
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
    GROUP BY
        c.customer_state,
        c.customer_unique_id
) AS customer_orders

GROUP BY customer_state;
```
---
# 9. 5단계 — 고객 500명 이상인 주만 남기기
문제에서는:
```plain text
total_customers >= 500
```
인 주만 필요하다.
현재:
```plain text
total_customers = COUNT(*)
```
이므로:
```sql
HAVING COUNT(*) >= 500
```
을 사용한다.
`WHERE`가 아니라 `HAVING`인 이유는:
```plain text
COUNT(*)
```
라는 집계 결과를 기준으로 필터링하기 때문이다.
---
# 10. 6단계 — 정렬
문제 조건:
```plain text
repeat_rate DESC
customer_state ASC
```
따라서:
```sql
ORDER BY
    repeat_rate DESC,
    customer_state ASC;
```
---
# 11. 최종 쿼리
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

    GROUP BY
        c.customer_state,
        c.customer_unique_id

) AS customer_orders

GROUP BY customer_state

HAVING COUNT(*) >= 500

ORDER BY
    repeat_rate DESC,
    customer_state ASC;
```
---
# 12. 실제 결과


| customer_state | total_customers | repeat_customers | repeat_rate |
| --- | --- | --- | --- |
| RJ | 12384 | 421 | 3.40 |
| MT | 876 | 29 | 3.31 |
| GO | 1952 | 64 | 3.28 |
| SP | 40302 | 1296 | 3.22 |
| RS | 5277 | 167 | 3.16 |
| MG | 11259 | 338 | 3.00 |
| DF | 2075 | 62 | 2.99 |
| PR | 4882 | 145 | 2.97 |
| ES | 1964 | 57 | 2.90 |
| BA | 3277 | 93 | 2.84 |
| SC | 3534 | 95 | 2.69 |
| MS | 694 | 18 | 2.59 |
| PA | 949 | 24 | 2.53 |
| PB | 519 | 13 | 2.50 |
| MA | 726 | 17 | 2.34 |
| PE | 1609 | 33 | 2.05 |
| CE | 1313 | 22 | 1.68 |


---
# 13. 이 문제를 읽었을 때 생각하는 순서
앞으로 비슷한 문제가 나오면 SQL부터 쓰지 않는다.
먼저 다음 순서로 생각한다.
```plain text
① 최종적으로 무엇을 세는가?

→ 고객


② 원본 데이터 한 행은 무엇인가?

→ 주문


③ 주문 데이터를 바로 세도 되는가?

→ X
   고객별 주문 횟수를 먼저 알아야 함


④ 따라서 중간 결과가 필요한가?

→ O


⑤ 중간 결과 한 행은 무엇인가?

→ 고객 1명


⑥ 중간 결과를 어떻게 만드는가?

→ GROUP BY state + customer


⑦ 최종 결과 한 행은 무엇인가?

→ state 1개


⑧ 다시 무엇으로 GROUP BY 하는가?

→ GROUP BY state
```
---
# 14. 서브쿼리가 필요한 이유
이 문제에서 서브쿼리는 단순히 SQL을 어렵게 만들기 위해 사용하는 것이 아니다.
우리가 원하는 중간 표가 필요하기 때문이다.
```plain text
원본 orders
```
에서는:
```plain text
고객 A
고객 A
고객 B
고객 C
고객 C
고객 C
```
처럼 고객이 여러 행에 존재한다.
먼저 이것을:
```plain text
고객 A | 2
고객 B | 1
고객 C | 3
```
으로 바꿔야 한다.
이 결과를 만드는 것이:
```sql
SELECT
    c.customer_state,
    c.customer_unique_id,
    COUNT(*) AS order_count
...
GROUP BY
    c.customer_state,
    c.customer_unique_id
```
이다.
그리고 이 **중간 결과를 하나의 새로운 테이블처럼 사용**하는 것이:
```sql
FROM (
    ...
) AS customer_orders
```
이다.
즉:
```plain text
서브쿼리
= 내가 먼저 만들어야 하는 중간 표
```
라고 이해하면 된다.
---
# 15. 이 문제의 핵심 한 문장
```plain text
주문을 바로 주별로 세는 것이 아니라,
먼저 고객별 주문 횟수를 만든 뒤
그 고객들을 다시 주별로 세는 문제다.
```
---
# 16. 가장 중요한 GROUP BY 변화
### 첫 번째 GROUP BY
```sql
GROUP BY
    customer_state,
    customer_unique_id
```
목적:
```plain text
고객 1명 = 1행
```
만들기.
### 두 번째 GROUP BY
```sql
GROUP BY customer_state
```
목적:
```plain text
주 1개 = 1행
```
만들기.
따라서 전체 구조는:
```plain text
주문 1행
   ↓
고객 1행
   ↓
주 1행
```
이다.


---
