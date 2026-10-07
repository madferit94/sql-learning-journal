# Day 04 — 학습 원기록

[English](../en/day04.md) · [목차](../../README.ko.md) · [편집·검증 안내](../../docs/editorial.ko.md)

> 노션 기록의 서식을 정리한 공개본입니다. 실패한 시도와 당시 결과를 보존했으며, 이번 게시 과정에서 SQL을 다시 실행하지 않았습니다. 

### 🛒 Day4 — Olist 주문 데이터·단일 테이블 분석
# `SQL` 학습 기록 — Day 4
## Olist 데이터 이해 + Single Table 분석
## 1. 오늘의 학습 목표
Sports 데이터에서 연습했던 기본 `SQL`을 실제 E-commerce 데이터인 Olist에 적용한다.
이번 학습에서는 먼저 `orders` 테이블의 구조와 주문 프로세스를 이해한 뒤, 단일 테이블에서 다음 개념을 연습했다.
- `SELECT`
- `WHERE`
- `GROUP BY`
- `HAVING`
- `ORDER BY`
- `COUNT()`
- `MIN()`
- `MAX()`
- `YEAR()` (MySQL 8.x 기준)
이번 Day의 핵심은 단순히 `SQL` 문법을 작성하는 것이 아니라,
분석 질문 → 필요한 컬럼 → 분석 단위 → 필터 → 집계 → 정렬
순서로 문제를 `SQL` 구조로 변환하는 것이다.
---
## 2. Dataset
Brazilian E-Commerce Public Dataset by Olist
MySQL에 구축할 주요 테이블:
- `orders`
- `customers`
- `order_items`
- `payments`
- `products`
- `sellers`
- `reviews`
- `category_translation`
`orders` 테이블의 실제 행 수:
99,441
## MySQL 8.x 데이터 타입 설계 메모
금액 컬럼은 원본 값과 소수 자릿수를 확인한 뒤 MySQL에서 적절한 숫자 타입으로 설계한다.
- `order_items.price`, `order_items.freight_value`, `payments.payment_value`: 원본 값·결측·소수 자릿수 확인 후 `DECIMAL(p,s)` 등 적절한 숫자 타입 검토
- `order_purchase_timestamp`, `order_approved_at`, 배송 관련 날짜 컬럼: 실제 문자열 형식과 결측을 확인한 뒤 `DATETIME` 또는 필요한 경우 `DATE` 검토
MySQL에서는 `DESCRIBE` 또는 `INFORMATION_SCHEMA.COLUMNS`로 실제 타입을 확인하고, 쿼리 재실행 결과를 검증한다.
---
## 3. 오늘 사용한 주요 컬럼


| English column | 한국어 의미 | Table | 실제 분석에서의 역할 |
| --- | --- | --- | --- |
| `order_id` | 주문 ID | `orders` | 개별 주문 식별 |
| `customer_id` | 고객 ID | `orders` | `customers` 테이블과 연결 |
| `order_status` | 주문 상태 | `orders` | 배송완료 등 주문 상태 필터링 |
| `order_purchase_timestamp` | 주문 발생 시각 | `orders` | 주문 시점 및 연도 추출 |
| `order_approved_at` | 주문 승인 시각 | `orders` | 주문/결제 승인 시점 확인 |
| `order_delivered_carrier_date` | 운송업체 전달 시각 | `orders` | 물류 시작 시점 확인 |
| `order_delivered_customer_date` | 고객 배송완료 시각 | `orders` | 실제 배송 완료 시점 확인 |
| `order_estimated_delivery_date` | 예상 배송일 | `orders` | 실제 배송일과 비교 |


주문 프로세스 이해
Purchase
↓
Approval
↓
Carrier
↓
Customer Delivery
Estimated Delivery
→ 실제 배송일과 비교 가능
---
### 문제 1 — 배송완료 주문 10건 조회
#### 문제
delivered 주문만 조회하고 다음 컬럼을 출력한다.
`order_id`
`order_status`
`order_purchase_timestamp`
가장 오래된 주문부터 10건 출력한다.
#### 첫 시도
```sql
SELECT order_id, order_status, order_purchase_timestamp
FROM orders
WHERE order_status = 'delivered'
ORDER BY order_id
LIMIT 10;
```
#### 문제점
`WHERE` 조건은 정확했지만 정렬 기준이 잘못됐다.
문제에서 요구한 것은 가장 오래된 주문부터인데,
`ORDER BY` `order_id`
로 주문 ID를 기준으로 정렬했다.
`SQL` 문법 오류라기보다 자연어 요구사항을 적절한 컬럼으로 연결하는 과정의 오류였다.
"가장 오래된 주문부터"
↓
`order_purchase_timestamp`
#### MySQL 8.x 기준 최종 쿼리
```sql
SELECT order_id, order_status, order_purchase_timestamp
FROM orders
WHERE order_status = 'delivered'
ORDER BY order_purchase_timestamp
LIMIT 10;
```
#### 실제 결과


| `order_id` | `order_status` | `order_purchase_timestamp` |
| --- | --- | --- |
| bfbd0f9b... | delivered | 2016-09-15 12:16:38 |
| 3b697a20... | delivered | 2016-10-03 09:44:50 |
| be5bc2f0... | delivered | 2016-10-03 16:56:50 |
| a41c8759... | delivered | 2016-10-03 21:13:36 |
| d207cc27... | delivered | 2016-10-03 22:06:03 |
| cd3b8574... | delivered | 2016-10-03 22:31:31 |
| ae8a60e4... | delivered | 2016-10-03 22:44:10 |
| ef1b29b5... | delivered | 2016-10-03 22:51:30 |
| 0a0837a5... | delivered | 2016-10-04 09:06:10 |
| 1ff217aa... | delivered | 2016-10-04 09:16:33 |


#### 핵심 개념
"오래된 주문부터"
↓
`order_purchase_timestamp`
↓
`ORDER BY` `order_purchase_timestamp` `ASC`
`ORDER BY`는 방향을 생략하면 기본적으로 `ASC`다.
---
### 문제 2 — 주문 상태별 주문 건수
#### 문제
`order_status`별 주문 건수를 계산하고 주문 건수가 많은 상태부터 출력한다.
#### 첫 시도
```sql
SELECT order_id, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC
LIMIT 10;
```
#### 문제점
그룹 기준은:
`GROUP BY` `order_status`
인데 `SELECT`에는:
`order_id`
가 들어갔다.
`order_id`는 그룹 기준도 아니고 집계값도 아니다.
MySQL 8.x의 기본 `ONLY_FULL_GROUP_BY`에서는 `order_id`가 그룹 기준이나 집계값이 아니므로 오류가 발생한다.
#### MySQL 8.x 기준 최종 쿼리
```sql
SELECT order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;
```
#### 실제 결과


| `order_status` | `order_count` |
| --- | --- |
| delivered | 96478 |
| shipped | 1107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |


전체 합계:
99,441 `orders`
#### 핵심 개념
집계 결과에서는 기본적으로 다음 관계를 확인한다.
```sql
SELECT
    그룹 기준,
    집계 함수

즉,

SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status;
```
처럼 무엇별로 집계하는지가 결과에도 나타나야 한다.
---
### 문제 3 — 배송완료 주문의 연도별 건수
#### 문제
delivered 주문만 대상으로 연도별 주문 건수를 계산한다.
출력:
`order_year` \| `order_count`
오래된 연도부터 정렬한다.
새로 사용한 함수 (MySQL 8.x 기준)
연도별 집계에는 MySQL의 `YEAR(order_purchase_timestamp)`를 사용한다.
`order_purchase_timestamp`에서 연도만 추출한다.
#### 첫 시도
```sql
SELECT order_status,
       YEAR(order_purchase_timestamp),
       COUNT(*) AS order_count
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_purchase_timestamp
ORDER BY order_count DESC
LIMIT 10;
```
#### 문제점
가장 중요한 오류는:
`GROUP BY` `order_purchase_timestamp`
였다.
문제는 연도별 분석인데 개별 주문 timestamp를 기준으로 그룹화했다.
또한 요구 출력에 없는 `order_status`를 출력했고 정렬 기준과 `LIMIT`도 문제 조건과 달랐다.
#### MySQL 8.x 기준 최종 쿼리
```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year;
```
#### 실제 결과


| `order_year` | `order_count` |
| --- | --- |
| 2016 | 267 |
| 2017 | 43428 |
| 2018 | 52783 |


#### 결과 검증
267 + 43,428 + 52,783
= 96,478
문제 2에서 확인한:
delivered = 96,478
과 정확히 일치한다.
#### 핵심 개념
분석 단위와 `GROUP BY` 단위를 일치시켜야 한다.
연도별 분석
↓
연도 추출
↓
`GROUP BY` `order_year`
---
### 문제 4 — 주문이 1,000건 이상인 연도
#### 문제
전체 주문을 연도별로 집계하고 주문 건수가 1,000건 이상인 연도만 출력한다.
주문 건수가 많은 연도부터 정렬한다.
#### 첫 시도
```sql
SELECT order_status,
       YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_status
HAVING order_count >= '1000'
ORDER BY order_count;
```
문제점 1 — 잘못된 `GROUP BY`
문제는 연도별 주문 건수인데:
`GROUP BY` `order_status`
로 상태별 그룹을 만들었다.
수정 과정에서도 `GROUP BY` `order_status`가 남아 있어:
2017 \| 96478
2018 \| 1107
처럼 표시됐다.
실제로 96,478은 delivered, 1,107은 shipped의 주문 건수다.
즉 그룹은 `order_status`인데 `SELECT`에서 그룹과 맞지 않는 `order_year`를 표시하면서 의미가 맞지 않는 결과가 생성됐다.
문제점 2 — 숫자 표현
`HAVING` `order_count` \>= '1000'
보다:
`HAVING` `order_count` \>= 1000
처럼 숫자 리터럴은 따옴표 없이 표현한다.
문제점 3 — 정렬 방향
`ORDER BY` `order_count`
는 기본적으로 오름차순이다.
문제는 주문 건수가 많은 순이므로 `DESC`가 필요하다.
#### MySQL 8.x 기준 최종 쿼리
```sql
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_year
HAVING order_count >= 1000
ORDER BY order_count DESC;
```
#### 실제 결과


| `order_year` | `order_count` |
| --- | --- |
| 2018 | 54011 |
| 2017 | 45101 |


2016년은 주문 건수가 1,000건 미만이므로 `HAVING` 조건에서 제외됐다.
#### 핵심 개념
연도별
→ `GROUP BY` `order_year`
그룹당 1,000건 이상
→ `HAVING` `order_count` \>= 1000
주문 건수가 많은 순
→ `ORDER BY` `order_count` `DESC`
`WHERE`와 `HAVING`의 차이:
`WHERE`
→ 그룹화 전에 개별 행을 필터링
`GROUP BY`
→ 행을 그룹으로 묶음
`HAVING`
→ 만들어진 그룹을 집계 결과로 필터링
---
### 문제 5 — 연도별 배송완료 주문 기간 확인
#### 문제
배송완료 주문을 연도별로 집계하고 다음을 확인한다.
`order_year`
`order_count`
`first_order`
`last_order`
#### 첫 시도
```sql
SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS order_count,
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year DESC;
```
#### 평가
SELECT, WHERE, GROUP BY, COUNT(), MIN(), MAX()는 첫 시도부터 정확했다.
문제는 정렬 방향 하나였다.
문제에서는 오래된 연도 → 최근 연도를 요구했지만:
ORDER BY order_year DESC
를 사용했다.
#### MySQL 8.x 기준 최종 쿼리
```sql

SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS order_count,
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_year
ORDER BY order_year;
```
#### 실제 결과


| `order_year` | `order_count` | `first_order` | `last_order` |
| --- | --- | --- | --- |
| 2016 | 267 | 2016-09-15 12:16:38 | 2016-12-23 23:16:47 |
| 2017 | 43428 | 2017-01-05 11:56:06 | 2017-12-31 23:29:31 |
| 2018 | 52783 | 2018-01-01 02:48:41 | 2018-08-29 15:00:37 |


#### 분석상 중요한 발견
연도별 주문 건수만 보면:
2016      267
2017   43,428
2018   52,783
이지만 각 연도의 데이터 수집 기간이 동일하지 않다.
2016년 데이터는 9월부터 시작하고, 2018년 데이터는 8월에 끝난다.
따라서 단순히:
2018년의 연간 주문 실적이 2017년보다 높았다.
라고 해석해서는 안 된다.
기간이 동일한지 확인한 후 비교해야 한다.
이것은 `SQL` 계산과 별개로 데이터 분석가가 반드시 확인해야 하는 검증 과정이다.
---
#### Day 4 핵심 정리
`SQL` 실행 순서
오늘 문제를 이해할 때 다음 흐름을 사용했다.
`FROM`
↓
`WHERE`
↓
`GROUP BY`
↓
집계 함수
↓
`HAVING`
↓
`ORDER BY`
↓
`LIMIT`
자연어 → `SQL` 변환
오늘 반복적으로 확인한 부분:
"무엇별로?"
↓
`GROUP BY` 무엇
"어떤 행만?"
↓
`WHERE`
"그룹 중 어떤 것만?"
↓
`HAVING`
"무엇이 많은 순?"
↓
`ORDER BY` 해당 지표 `DESC`
"오래된 것부터?"
↓
`ORDER BY` 날짜 `ASC`
---
#### Day 4 회고
오늘의 오류는 `SQL` 문법 자체보다는 분석 요구사항을 `SQL` 구조로 변환하는 과정에서 주로 발생했다.
특히 반복된 오류는 다음 세 가지였다.
## 1. 분석 단위와 `GROUP BY` 컬럼 불일치
## 2. 문제에서 요구한 정렬 대상 또는 `ASC`/`DESC` 방향 불일치
## 3. MySQL의 `GROUP BY` 규칙
반면 후반부 문제에서는 개선이 나타났다.
문제 5에서는 처음 사용하는 `MIN()`과 `MAX()`를 기존의:
`WHERE` → `GROUP BY` → 집계
구조에 바로 결합했다.
따라서 현재 우선적으로 강화해야 할 부분은 새로운 `SQL` 문법을 더 많이 배우는 것보다:
문제를 읽고 분석 단위·필터·집계값·정렬 기준을 먼저 분리한 후 `SQL`을 작성하는 습관
이다.
---
#### 다음 학습 — Day 5
Day 5부터는 Olist의 두 번째 단계로 넘어간다.
`orders`
↓
`customer_id`
↓
`customers`
먼저 `customers` 테이블의 스키마를 이해하고 다음 컬럼의 차이를 확인한다.
`customer_id`
`customer_unique_id`
`customer_city`
`customer_state`
특히:
`customer_id` ≠ `customer_unique_id`
라는 점이 중요하다.
그 후 `orders` ↔ `customers` 관계를 이용해 단일 테이블 집계에서 `JOIN` 기반 고객·지역 분석으로 확장한다.
Day 5 학습 순서:
`customers` 스키마 이해
↓
`customer_id`와 `customer_unique_id` 차이
↓
`orders` ↔ `customers` 관계 확인
↓
`INNER JOIN` 기초
↓
지역별 주문 분석
↓
`JOIN` 결과 검증
