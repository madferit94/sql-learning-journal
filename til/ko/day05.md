# Day 05 — 학습 원기록

[English](../en/day05.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### 👥 Day5 — Olist 고객 데이터·JOIN 기초
# `SQL` 학습 기록 — Day 5
## Olist 고객 관계 이해 + `orders` ↔ `customers` `JOIN` 기초
## 1. 오늘의 학습 목표
Day 4에서는 `orders` 단일 테이블을 이용해 주문 건수와 주문 시점을 분석했다.
Day 5에서는 `customers` 테이블을 추가하여:
주문이 언제, 얼마나 발생했는가? → 어떤 고객과 지역에서 주문이 발생했는가?
로 분석 범위를 확장했다.
오늘의 핵심 학습 내용:
- `customer_id`와 `customer_unique_id` 차이
- `GROUP BY`와 `HAVING` 복습
- `INNER JOIN`
- `ON`을 이용한 테이블 관계 정의
- 여러 컬럼을 이용한 `GROUP BY`
- 여러 기준을 이용한 `ORDER BY`
- `JOIN` 전후 행 수 검증
- `SQL`이 실행되는 것과 논리적으로 올바른 결과를 만드는 것의 차이
---
## 2. 오늘 사용한 테이블 관계
`orders`
│
│ `customer_id`
│
▼
`customers`
`JOIN` 조건:
`ON` `orders`.`customer_id` = `customers`.`customer_id`
실제 작성에서는 alias를 사용했다.
`FROM` `orders` `AS` o
`JOIN` `customers` `AS` c
`ON` o.`customer_id` = c.`customer_id`
---
## 3. 오늘 사용한 주요 컬럼


| English column | 한국어 의미 | Table | 실제 분석에서의 역할 |
| --- | --- | --- | --- |
| `customer_id` | 주문 단위 고객 ID | `orders`, `customers` | 두 테이블 `JOIN` 기준 |
| `customer_unique_id` | 실제 고객 고유 ID | `customers` | 동일 고객의 반복 등장/재구매 분석 |
| `customer_zip_code_prefix` | 우편번호 앞자리 | `customers` | 세부 지역 분석 가능 |
| `customer_city` | 고객 도시 | `customers` | 도시별 주문 분석 |
| `customer_state` | 고객 주(State) | `customers` | State별 주문 분석 |
| `order_status` | 주문 상태 | `orders` | delivered 주문 필터링 |
| `order_purchase_timestamp` | 주문 발생 시각 | `orders` | 주문 연도 추출 |


---
## 4. `customer_id` vs `customer_unique_id`
오늘 실제 데이터로 두 ID의 차이를 확인했다.
개념적으로:
실제 고객 A
주문 1 → `customer_id` = AAA
주문 2 → `customer_id` = BBB
주문 3 → `customer_id` = CCC
`customer_unique_id` = USER_A
따라서:
`orders` ↔ `customers` 연결
→ `customer_id`
실제 고객 식별
→ `customer_unique_id`
재구매 고객 분석
→ `customer_unique_id`
두 컬럼을 같은 의미로 사용하면 안 된다.
---
### 문제 1 — `customer_id` 중복 검증
#### 문제
`customers` 테이블에서 `customer_id`별 행 수를 계산하고 2개 이상 존재하는 ID가 있는지 확인한다.
출력:
`customer_id` \| customer_count
---
#### 첫 시도
```sql
SELECT customer_id, COUNT(*) customer_count
FROM customers
GROUP BY customer_id
HAVING customer_count >= 2
ORDER BY customer_id DESC;
```
#### 실제 결과


| 결과 |
| --- |
| 0 rows |


이 쿼리는 핵심적으로 맞았다.
결과가 없다는 것은 현재 `customers` 테이블에서 동일한 `customer_id`가 2회 이상 등장하지 않았다는 뜻이다.
다만 문제에서는 중복 횟수가 많은 순으로 확인하는 것이 목적이었으므로 정렬 기준은 다음이 더 적절하다.
`ORDER BY` customer_count `DESC`
---
두 번째 시도에서 발생한 오류
결과가 나오지 않자 다음과 같이 수정했다.
```sql
SELECT customer_id, COUNT(*) customer_count
FROM customers
GROUP BY customer_count
HAVING customer_count >= 2
ORDER BY customer_id DESC;
```
확인된 오류:
Parse error:
aggregate functions are not allowed in the `GROUP BY` clause
왜 틀렸는가?
customer_count는:
`COUNT`(\*)
라는 집계 결과다.
따라서:
`GROUP BY` customer_count
는 사실상:
`GROUP BY` `COUNT`(\*)
를 시도한 것이다.
`GROUP BY`는 집계하기 전에 무엇을 하나의 그룹으로 묶을 것인지 결정한다.
---
#### 최종 구조
```sql
SELECT customer_id,
       COUNT(*) AS customer_count
FROM customers
GROUP BY customer_id
HAVING customer_count >= 2
ORDER BY customer_count DESC;
```
#### 핵심 개념
`GROUP BY` `customer_id`
→ 고객 ID별 그룹 생성
`COUNT`(\*)
→ 각 그룹의 행 수 계산
`HAVING` customer_count \>= 2
→ 2회 이상 등장한 그룹만 선택
그리고 결과가 0행인 것도 유효한 분석 결과다.
---
### 문제 2 — 반복 등장하는 `customer_unique_id`
#### 문제
`customer_unique_id`별 등장 횟수를 계산하고 2회 이상 등장한 실제 고객 중 상위 10명을 확인한다.
출력:
`customer_unique_id` \| customer_count
---
#### 첫 시도
```sql
SELECT customer_unique_id, COUNT(*) customer_count
FROM customers
HAVING customer_unique_id > 1
ORDER BY customer_unique_id;
```
#### 실제 결과


| `customer_id` | `customer_count` |
| --- | --- |
| 861eff4711a542e4b93843c6dd7febb0 | 99441 |


문제점 1 — `GROUP BY` 누락
`GROUP BY`가 없기 때문에 전체 `customers` 테이블을 하나의 집계 대상으로 계산했다.
`customers` 전체
99,441 rows
↓
`GROUP BY` 없음
↓
`COUNT`(\*)
↓
99,441
그래서 customer_count = 99,441이라는 값이 나왔다.
문제점 2 — `HAVING` 대상 오류
`HAVING` `customer_unique_id` \> 1
`customer_unique_id`는 횟수가 아니라 문자열 형태의 고객 식별자다.
우리가 알고 싶은 것은:
`customer_unique_id` 값이 2 이상인가? ❌
각 `customer_unique_id`의
등장 횟수가 2 이상인가? ✅
---
#### 두 번째 시도
```sql
SELECT customer_unique_id, COUNT(*) customer_count
FROM customers
GROUP BY customer_unique_id
HAVING customer_unique_id >= 2
ORDER BY customer_count DESC
LIMIT 10;
```
#### 실제 결과


| `customer_unique_id` | `customer_count` |
| --- | --- |
| 8d50f5... | 17 |
| 3e43e6... | 9 |
| ca7702... | 7 |
| 6469f9... | 7 |
| f0e310... | 6 |


...
결과가 정상처럼 보였지만 논리는 아직 잘못되어 있었다.
문제는:
`HAVING` `customer_unique_id` \>= 2
였다.
필터링해야 하는 대상은 ID 자체가 아니라 ID별 등장 횟수다.
이 문제를 통해:
결과가 그럴듯하게 나온다고 해서 `SQL`이 논리적으로 올바른 것은 아니다.
라는 점을 확인했다.
---
#### MySQL 8.x 기준 최종 쿼리
```sql
SELECT customer_unique_id,
       COUNT(*) AS customer_count
FROM customers
GROUP BY customer_unique_id
HAVING customer_count >= 2
ORDER BY customer_count DESC
LIMIT 10;
```
#### 실제 결과


| `customer_unique_id` | `customer_count` |
| --- | --- |
| 8d50f5eadf50201ccdcedfb9e2ac8455 | 17 |
| 3e43e6105506432c953e165fb2acf44c | 9 |
| ca77025e7201e3b30c44b472ff346268 | 7 |
| 6469f99c1f9dfae7733b25662e7f1782 | 7 |
| 1b6c7548a2a1f9037c1fd3ddfed95f33 | 7 |
| f0e310a6839dce9de1638e0fe5ab282a | 6 |
| de34b16117594161a6a89c50b289d35a | 6 |
| dc813062e0fc23409cd255f7f53c7074 | 6 |
| 63cfc61cee11cbe306bff5857d00bfe4 | 6 |
| 47c1a3033b8b77b3ab6e109eb4d5fdf3 | 6 |


데이터에서 확인한 차이
`customer_id`
→ 2회 이상 등장한 ID 없음
`customer_unique_id`
→ 반복 등장
→ 최대 17회
따라서 두 ID는 분석 목적이 다르다.
---
### 문제 3 — 첫 `JOIN`: State별 배송완료 주문
#### 문제
`orders`와 `customers`를 연결하여 delivered 주문의 State별 주문 건수를 계산한다.
출력:
`customer_state` \| `order_count`
상위 10개 State를 주문 건수가 많은 순으로 출력한다.
---
#### 첫 시도
```sql
SELECT customer_state, COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY order_count DESC
LIMIT 10;
```
결과
첫 시도 정답.
#### 실제 결과


| `customer_state` | `order_count` |
| --- | --- |
| SP | 40501 |
| RJ | 12350 |
| MG | 11354 |
| RS | 5345 |
| PR | 4923 |
| SC | 3546 |
| BA | 3256 |
| DF | 2080 |
| ES | 1995 |
| GO | 1957 |


---
`JOIN` 구조
`orders`
│
│ `customer_id`
│
├──────────────┐
│
▼
`customers`
│
└─ `customer_state`
`orders`에는 고객의 State 정보가 없기 때문에 `customers` 테이블을 연결해야 한다.
`ON` o.`customer_id` = c.`customer_id`
는:
`orders`의 `customer_id`와 `customers`의 `customer_id`가 같은 행을 연결한다.
라는 의미다.
#### 핵심 개념
`FROM` → 기준 테이블
`JOIN` → 추가할 테이블
`ON` → 두 테이블의 관계
`WHERE` → 필요한 행 필터
`GROUP BY` → 분석 단위
`COUNT`(\*) → 그룹별 행 수
`ORDER BY` → 결과 정렬
---
### 문제 4 — 연도별 + State별 주문 건수
#### 문제
delivered 주문을 대상으로 연도별·State별 주문 건수를 계산한다.
출력:
`order_year` \| `customer_state` \| `order_count`
정렬:
연도 오래된 순
→ 같은 연도에서는 주문 건수 많은 순
---
#### 첫 시도
```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       customer_state,
       COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY order_year DESC
LIMIT 20;
```
#### 문제점
SELECT에서는:
order_year
customer_state
두 개의 분석 차원을 출력하고 있지만:
GROUP BY customer_state
만 사용했다.
따라서 실제 집계는 전체 기간의 State별 주문 건수였다.
예:
MG \| 11,354
SP \| 40,501
RJ \| 12,350
이 값들은 문제 3의 전체 기간 State별 주문 건수와 동일했다.
MySQL 8.x의 기본 `ONLY_FULL_GROUP_BY`에서는 `order_year`가 `GROUP BY`에 없어 오류가 발생한다.
2018 \| MG \| 11354
2017 \| SP \| 40501
같은 결과가 나타났지만 이것을 실제 연도별 주문 건수라고 해석하면 안 된다.
⸻
두 번째 시도
```sql

SELECT YEAR(order_purchase_timestamp) AS order_year,
       customer_state,
       COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY order_year AND customer_state
ORDER BY order_year DESC
LIMIT 20;
```
#### 실제 결과


| `order_year` | `customer_state` | `order_count` |
| --- | --- | --- |
| 2017 | SP | 96478 |


#### 문제점
`GROUP BY` `order_year` `AND` `customer_state`
에서 `AND`를 사용했다.
하지만 `AND`는 여러 그룹 기준을 나열하는 문법이 아니라 논리 조건을 결합하는 연산자다.
여러 컬럼을 그룹 기준으로 사용할 때는 쉼표를 사용한다.
`GROUP BY` A, B
---
#### 세 번째 시도
```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       customer_state,
       COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY order_year, customer_state
ORDER BY order_year DESC, order_count DESC
LIMIT 20;
```
결과
그룹화는 정확해졌다.
2018 \| SP \| 23335
2018 \| RJ \| 6342
2018 \| MG \| 6079
...
하지만 문제에서는 오래된 연도부터를 요구했으므로:
`ORDER BY` `order_year` `DESC`
가 반대였다.
---
#### MySQL 8.x 기준 최종 쿼리
```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       customer_state,
       COUNT(*) AS order_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY order_year, customer_state
ORDER BY order_year, order_count DESC
LIMIT 20;
```
#### 실제 결과


| `order_year` | `customer_state` | `order_count` |
| --- | --- | --- |
| 2016 | SP | 95 |
| 2016 | RJ | 40 |
| 2016 | MG | 35 |
| 2016 | PR | 20 |
| 2016 | RS | 17 |
| 2016 | SC | 9 |
| 2016 | GO | 7 |
| 2016 | PE | 6 |
| 2016 | DF | 6 |
| 2016 | CE | 6 |
| 2016 | RN | 4 |
| 2016 | PA | 4 |
| 2016 | MA | 4 |
| 2016 | SE | 3 |
| 2016 | ES | 3 |
| 2016 | BA | 3 |
| 2016 | RR | 1 |
| 2016 | PI | 1 |
| 2016 | PB | 1 |
| 2016 | MT | 1 |


#### 핵심 개념
여러 그룹 기준:
`GROUP BY` `order_year`, `customer_state`
여러 정렬 기준:
`ORDER BY` `order_year` `ASC`,
`order_count` `DESC`
역할 차이:
`WHERE` A `AND` B
→ 여러 조건을 동시에 만족
`GROUP BY` A, B
→ A와 B의 조합별 그룹
`ORDER BY` A, B
→ A로 먼저 정렬하고 같은 A 안에서 B로 정렬
---
### 문제 5 — `JOIN` 전후 행 수 검증
#### 문제
`orders`와 `customers`를 `customer_id`로 `JOIN`한 뒤 delivered 주문 수가 `JOIN` 전과 동일한지 확인한다.
---
#### 첫 시도
```sql
SELECT COUNT(*) AS joined_delivered_count
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE order_status = 'delivered';
```
결과
첫 시도 정답.
#### 실제 결과


| `joined_delivered_count` |
| --- |
| 96478 |


기존에 확인한 `JOIN` 전 delivered 주문:
96,478
`JOIN` 후:
96,478
따라서:
`JOIN` 전       96,478
↓
`orders`.`customer_id`
=
`customers`.`customer_id`
↓
`JOIN` 후       96,478
차이              0
현재 delivered 주문 기준으로 이 `JOIN`에서 행 손실이나 행 증폭이 관찰되지 않았다.
---
## 5. `JOIN` 검증에서 배운 점
`JOIN` 문법이 실행됐다고 바로 분석을 시작하면 안 된다.
`JOIN` 전후 행 수를 확인해야 한다.
Case 1 — 행 수가 증가
예:
`JOIN` 전  96,478
`JOIN` 후 120,000
가능성:
1:N `JOIN`
중복 key
여러 행이 한 주문에 매칭
Case 2 — 행 수가 감소
예:
`JOIN` 전 96,478
`JOIN` 후 90,000
가능성:
`INNER JOIN`에서
매칭되지 않는 주문이 제거됨
Case 3 — 이번 결과
`JOIN` 전 96,478
`JOIN` 후 96,478
문제 1에서 `customers`.`customer_id`의 중복도 발견되지 않았다.
따라서 현재 확인 범위에서는:
`orders` ↔ `customers`
`customer_id` `JOIN`
→ delivered 주문 행 수 유지
를 검증했다.
단, 이것을 Olist의 모든 테이블에 일반화하면 안 된다.
향후:
`orders`
│
├── `order_items`
│      1 : N
│
└── `payments`
1 : N
관계에서는 하나의 주문이 여러 행으로 증가할 수 있다.
따라서 향후 매출 등을 계산할 때 `JOIN`으로 인한 중복 집계를 반드시 확인해야 한다.
---
## 6. Day 5 오답 패턴 정리
오늘 발생한 오류는 크게 네 가지다.
① `GROUP BY` 누락
```sql
SELECT customer_unique_id, COUNT(*)
FROM customers;
```
처럼 그룹화하지 않으면 전체 테이블이 하나의 집계 대상이 된다.
99,441 rows
→ `COUNT`(\*)
→ 99,441
---
② `HAVING` 대상 혼동
잘못된 생각:
`HAVING` `customer_unique_id` \>= 2
올바른 질문:
고객 ID 값이 2 이상인가?
가 아니라:
각 고객 ID의 등장 횟수가 2 이상인가?
이다.
따라서:
`HAVING` customer_count \>= 2
가 되어야 한다.
---
③ 여러 `GROUP BY` 기준에서 `AND` 사용
잘못된 형태:
`GROUP BY` `order_year` `AND` `customer_state`
올바른 형태:
`GROUP BY` `order_year`, `customer_state`
기억:
조건 + 조건
→ `AND`
그룹 기준 + 그룹 기준
→ ,
정렬 기준 + 정렬 기준
→ ,
---
④ 정렬 방향 확인 부족
문제에서:
오래된 연도부터
라고 했는데:
`ORDER BY` `order_year` `DESC`
를 사용했다.
`SQL`을 작성하기 전에:
오래된 → 최근 = `ASC`
최근 → 오래된 = `DESC`
적은 → 많은 = `ASC`
많은 → 적은 = `DESC`
를 먼저 판단한다.
---
## 7. Day 5에서 잘한 부분
첫 `JOIN`을 독립적으로 작성
문제 3에서 처음으로 `orders` ↔ `customers` `JOIN`을 사용했지만 첫 시도에 다음 구조를 정확하게 작성했다.
`FROM` `orders` `AS` o
`JOIN` `customers` `AS` c
`ON` o.`customer_id` = c.`customer_id`
`WHERE` ...
`GROUP BY` ...
`ORDER BY` ...
`LIMIT` ...
즉 `JOIN` 자체의 기본 구조는 이해하고 있다.
`JOIN` 검증 문제도 첫 시도 정답
문제 5에서:
`COUNT`(\*)
를 이용해 `JOIN` 후 행 수를 직접 검증했다.
이는 단순 `SQL` 작성보다 실제 데이터 분석에서 더 중요한 습관이다.
---
## 8. Day 5 회고
Day 5에서는 새로운 `JOIN` 문법보다 오히려 기존의 `GROUP BY`와 `HAVING`에서 오류가 더 많이 발생했다.
현재 상태를 구분하면:
```sql
SELECT / WHERE
→ 비교적 안정적
COUNT / GROUP BY
→ 기본 개념은 이해
→ 분석 단위가 복수이거나 문제 표현이 바뀌면 실수 발생
HAVING
→ 무엇을 조건으로 걸어야 하는지 추가 반복 필요
ORDER BY
→ 컬럼 선택은 가능
→ ASC/DESC 조건 확인 실수 반복
JOIN / ON
→ 첫 적용은 안정적

따라서 지금 단계에서 복잡한 SQL 문법을 빠르게 추가하기보다는:

분석 단위 → GROUP BY → 집계값 → HAVING → 정렬 기준

을 문제를 읽자마자 먼저 구분하는 연습이 필요하다.

⸻

9. SQL 작성 전 체크리스트

앞으로 문제를 보면 바로 코드를 작성하기 전에 다음을 먼저 생각한다.

① 분석 단위가 무엇인가?
   → GROUP BY
② 어떤 행만 필요한가?
   → WHERE
③ 무엇을 계산하는가?
   → COUNT / SUM / AVG ...
④ 집계 결과에 조건이 있는가?
   → HAVING
⑤ 어떤 순서인가?
   → ORDER BY + ASC/DESC
⑥ 다른 테이블의 정보가 필요한가?
   → JOIN
⑦ 어떤 key로 연결하는가?
   → ON
⑧ JOIN 후 행 수가 변했는가?
   → 검증

⸻

10. Day 5 핵심 한 줄

SQL이 실행되고 결과가 나온다는 것만으로는 충분하지 않다. 분석 단위와 집계 조건이 질문과 일치하는지 확인하고, JOIN 후에는 행 수가 의도치 않게 변하지 않았는지 검증해야 한다.

⸻

다음 학습 — Day 6

Day 5에서:

orders
   ↓
customers

라는 비교적 안전한 관계를 다뤘다.

다음 단계에서는 Olist의 주문 상세 구조로 확장할 수 있다.

orders
   ↓
order_items

여기서는 orders ↔ customers와 달리 1:N 관계가 등장한다.

따라서 다음 학습의 핵심은 단순 JOIN이 아니라:

한 주문에 상품이 몇 개 있는가?
JOIN하면 왜 행 수가 늘어나는가?
COUNT(*)와 COUNT(DISTINCT order_id)는 왜 달라지는가?
price와 freight_value는 어떤 의미인가?
JOIN 후 매출을 계산할 때 무엇을 조심해야 하는가?

를 실제 데이터로 확인하는 것이다.

MySQL 데이터베이스를 구축할 때는 `order_items.price`, `order_items.freight_value`, `payments.payment_value`의 실제 값·결측·소수 자릿수를 확인한 뒤 `DECIMAL(p,s)` 등 적절한 숫자 타입으로 설계한다. 날짜/시간 컬럼도 실제 형식과 결측을 확인한 뒤 `DATE` 또는 `DATETIME`으로 설계하고, MySQL에서는 `DESCRIBE`, `INFORMATION_SCHEMA.COLUMNS`, `CAST()` 또는 `CONVERT()`를 사용해 타입과 변환을 검증한다.
```

---
