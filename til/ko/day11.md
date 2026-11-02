# 🛒 Day11 — Olist 집계·조건부 COUNT·서브쿼리

[English](../en/day11.md) · [목차](../../README.ko.md) · [검증 기록](../../docs/audit.ko.md)

<details>
<summary>🛒 Day11 — Olist 집계·조건부 COUNT·서브쿼리</summary>

# SQL 학습 기록 — Day 11

## 🛒 Olist SQL — GROUP BY·HAVING·조건부 집계와 서브쿼리

- 학습일: 2026-09-30
- 환경: MySQL 8.4

<details>
<summary>📚 문제 1\~3 — GROUP BY·HAVING·조건부 집계</summary>

📚 문제 1\~3 — GROUP BY·HAVING·조건부 집계\</summary>

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

```txt
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

```txt
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

```txt
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

```txt
SP 주문 수 = 23,871
SP 실제 고객 수 = 23,289
```

같은 고객이 여러 번 주문했기 때문에 차이가 발생한다.

---

# 문제 3 — 2018년 주별 전체·배송 완료·취소 주문 수

<b>학습일:</b> 2026-09-30

<b>최종 검증일:</b> 2026-10-10

<b>누적 SQL Day 번호:</b> Day11 — 기존 원문 상위 토글에서 확인

<b>문제 번호:</b> P3 / 5

<b>해결 상태:</b> ✅ 검증 완료 — 사용자 직접 재실행 결과 기준

<b>기록 근거:</b> MySQL 실행 기록의 결과표와 실행 시간.

---

## 1. 문제

Olist의 `orders`, `customers` 테이블을 이용하여 2018년에 발생한 주문을 주(state)별로 집계한다.

다음 네 개의 컬럼을 출력한다.

- `customer_state`: 고객 주
- `total_order_count`: 전체 주문 수
- `delivered_count`: 배송 완료 주문 수
- `canceled_count`: 취소 주문 수

### 조건

- 2018년에 발생한 주문만 사용
- 전체 주문 수가 1,000건 이상인 주만 출력
- 전체 주문 수 내림차순
- 주문 수가 같다면 주 이름 오름차순

### 결과 한 행의 의미

주(state) 하나에 대한 주문 통계.

### JOIN 키

```sql
orders.customer_id = customers.customer_id
```

### 집계 기준

```sql
GROUP BY c.customer_state
```

---

## 2. 내 첫 시도

아래 쿼리는 처음 직접 작성한 코드다. 오답을 수정본으로 덮어쓰지 않고 기존 기록 그대로 보존한다.

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

---

## 3. 실행 결과·오류

### 첫 시도

최초 쿼리의 실제 실행 결과는 공유되지 않았다. 코드 검토 과정에서 다음 두 가지 오류를 발견했다.

1. `CASE WHEN`에서 `THEN` 누락
2. `HAVING`에서 잘못된 집계 기준 사용

### 수정 후 실행 오류

이후 수정한 쿼리를 MySQL에 붙여 넣었지만 다음 오류가 발생했다.

```txt
ERROR 1064 (42000):
You have an error in your SQL syntax
```

과거 오류 위치는 `JOIN customers` 부근으로 기록되어 있습니다. 공백 정리 후 정상 실행했으나 당시 실패 입력의 원문 바이트가 없어 특수 공백을 유일한 원인으로 독립 재현하지는 못했습니다. 공백 문제는 당시 해결 기록의 진단으로 구분합니다.

---

## 4. 틀린 이유

### 오류 1. HAVING 기준을 잘못 선택

첫 시도:

```sql
HAVING canceled_count >= 1000
```

문제는 취소 주문이 1,000건 이상인 주가 아니라 전체 주문이 1,000건 이상인 주를 요구한다.

수정:

```sql
HAVING total_order_count >= 1000
```

### 오류 2. CASE WHEN의 THEN 누락

첫 시도:

```sql
COUNT(CASE WHEN order_status = 'delivered' END)
```

수정:

```sql
COUNT(
    CASE
        WHEN o.order_status = 'delivered' THEN 1
    END
)
```

조건을 만족하면 1을 반환하고, ELSE를 생략했으므로 조건에 맞지 않으면 NULL을 반환한다. COUNT는 NULL을 제외하므로 해당 상태의 주문 수만 계산한다.

### 실행 환경 점검: 특수 공백 가능성

SQL 분석 논리가 올바르더라도 특수 공백이 포함되면 MySQL에서 문법 오류가 발생할 수 있다. 이 문제는 SQL 집계 논리 오류와 별개로 기록한다.

---

## 5. 수정 쿼리 — 최종 답안

공백을 정리한 최종 실행 쿼리입니다. 이 SQL은 이번 Olist 백업 재검증에서도 정상 실행됐습니다.

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
    c.customer_state ASC;
```

### 작성 및 수정 이력

- 전체 주문 수 기준으로 HAVING 조건 적용
- CASE WHEN에 THEN 반환값 추가
- 특수 공백 제거 후 정상 실행

---

## 6. 검증

### 최초 학습일 — 2026-09-30

- 정답 논리 완성
- 문법 오류 발생, 당시 해결 기록에서는 특수 공백 가능성으로 진단
- 최종 결과표 미확인

당시 상태를 이력으로 보존한다.

```txt
쿼리 논리 완성 ✅
실제 최종 결과 검증 ❌
```

### 재검증일 — 2026-10-10

정리된 SQL을 MySQL에서 재실행했습니다.

<b>실제 실행 결과 — 사용자 제공:</b>

| customer_state | total_order_count | delivered_count | canceled_count |
| --- | --- | --- | --- |
| SP | 23871 | 23335 | 188 |
| RJ | 6571 | 6342 | 37 |
| MG | 6181 | 6079 | 36 |
| RS | 2780 | 2737 | 13 |
| PR | 2755 | 2711 | 13 |
| SC | 1906 | 1884 | 8 |
| BA | 1784 | 1726 | 8 |
| DF | 1213 | 1193 | 2 |
| ES | 1061 | 1047 | 4 |
| GO | 1056 | 1033 | 5 |

```txt
10 rows in set (0.58 sec)
```

### 검증 결과

- [x] 2018년 주문 필터 적용
- [x] 고객 주별 집계
- [x] 전체 주문 수 계산
- [x] 배송 완료 주문 수 계산
- [x] 취소 주문 수 계산
- [x] 전체 주문 1,000건 이상 조건
- [x] 지정된 정렬 조건
- [x] MySQL 정상 실행
- [x] 실제 출력 결과 확인

<b>최종 상태: 검증 완료</b>

---

## 7. 결과 해석 및 주의점

### SP주 예시

2018년에 구매한 주문 중 고객 주가 SP인 주문은 총 23,871건이다.

- 배송 완료: 23,335건
- 취소: 188건

전체 주문 수는 배송 완료와 취소 주문뿐 아니라 다른 주문 상태까지 포함한다. 따라서 다음 등식은 일반적으로 성립하지 않는다.

```txt
total_order_count = delivered_count + canceled_count
```

또한 이 문제의 결과는 주문 건수이며, 실제 고객 수와는 다르다. 같은 고객이 여러 번 주문했다면 각 주문이 별도로 집계된다.

### 날짜 해석

2018년에 구매한 주문을 대상으로 한다. 2018년에 배송이 완료된 모든 주문을 집계하는 문제와는 다르다.

---

## 8. 핵심 개념 정리

이번 문제는 주문을 주별로 묶은 다음, 각 주에서 전체 주문이 몇 건인지 먼저 계산한다.

그중 delivered인 주문과 canceled인 주문을 CASE WHEN으로 따로 세는 문제다.

CASE WHEN은 조건에 맞으면 1을 반환한다. COUNT는 NULL을 세지 않으므로 특정 상태의 주문 수만 계산할 수 있다.

HAVING에서는 어떤 집계값을 기준으로 필터링하라는 문제인지 정확히 읽어야 한다.

또 SQL 오류가 나면 집계 논리만 확인하지 말고 공백 문자나 복사 과정의 문제도 확인해야 한다.

---

## 복습 체크포인트

다시 풀 때 확인할 질문:

1. `COUNT(*)`와 `COUNT(CASE WHEN...)`의 차이는?
2. 왜 GROUP BY에는 customer_state만 사용하는가?
3. 왜 HAVING canceled_count >= 1000이 틀렸는가?
4. 전체 주문 수와 delivered + canceled가 다른 이유는?

<b>복습 권장:</b> 이전 정답을 보지 않고 주별 주문 상태별 조건부 집계를 다시 작성하기.

---

</details>

<details>
<summary>🧩 문제 4 — 주별 반복 구매 고객 수</summary>

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

```txt
state | customer | order_count
------------------------------
SP    | A        | 1
SP    | B        | 3
SP    | C        | 2
RJ    | D        | 1
```

현재:

```txt
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

```txt
customer_orders
```

라는 이름을 붙인 것이다.

즉:

```txt
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

```txt
customer | order_count
----------------------
A        | 1
B        | 3
C        | 2
D        | 1
```

CASE 적용:

```txt
A → 0
B → 1
C → 1
D → 0
```

그리고:

```txt
0 + 1 + 1 + 0
= 2
```

따라서:

```txt
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

```txt
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
</details>

<details>
<summary>🧩 문제 5 — 2018년 주별 반복 구매율</summary>

# 문제 5 — 2018년 주별 반복 구매 고객 비율

## 문제

2018년 주문을 대상으로 주별:

```txt
실제 고객 수
반복 구매 고객 수
반복 구매율
```

을 계산한다.

반복 구매 고객:

```txt
2018년에 2회 이상 주문한 실제 고객
```

반복 구매율:

```txt
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

```txt
2018년에 고객 한 명이 몇 번 주문했는가?
```

현재 한 행:

```txt
실제 고객 1명
```

---

## STEP 2 — 전체 고객 수

서브쿼리 결과가:

```txt
고객 1명 = 1행
```

이므로:

```sql
COUNT(*) AS total_customers
```

를 사용한다.

중요:

```txt
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

```txt
2회 이상 구매 → 1
1회 구매 → 0
```

전부 더하면 반복 구매 고객 수가 된다.

---

## STEP 4 — 반복 구매율

```txt
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

```txt
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

```txt
한 행 = 주문
```

인데 최종적으로 고객을 분석해야 했다.

따라서 먼저:

```txt
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

```txt
고객 1명 = 1행
```

---

## 두 번째 GROUP BY

```sql
GROUP BY customer_state
```

목적:

```txt
주 1개 = 1행
```

---

# 오늘 가장 중요한 구조

```txt
주문 1행
↓
고객 1행
↓
주 1행
```

또는:

```txt
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
</details>

<details>
<summary>🧠 오늘의 핵심 정리·다음 학습</summary>

# 오늘 주요 오류 패턴

## 1. 문제 조건을 정확하게 읽지 않음

P1:

```txt
ORDER BY 누락
```

P2:

```txt
2018년 문제인데 2017년 사용
```

P3:

```txt
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

```txt
ERROR 1064
```

가 발생할 수 있다.

정상적인 쿼리가 이상한 위치에서 syntax error가 나면:

```txt
에러 직전 공백 삭제
→ 직접 스페이스바 입력
```

도 확인한다.

---

# 오늘 문제별 핵심

## P1

```txt
YEAR
GROUP BY
HAVING
ORDER BY
```

기본 집계 복습.

## P2

```txt
COUNT(*)
vs
COUNT(DISTINCT ...)
```

주문 수와 실제 고객 수 구분.

## P3

```txt
CASE WHEN
조건부 COUNT
```

한 행에서 여러 상태별 개수를 계산.

## P4

```txt
고객별 주문 횟수
→ 반복 고객 여부
→ 주별 반복 고객 수
```

쉬운 2단계 집계.

## P5

```txt
고객별 주문 횟수
→ 전체 고객
→ 반복 고객
→ 반복 구매율
```

2단계 집계 응용.

---

# 현재 이해가 필요한 부분

현재 완성 쿼리는 참고하면 작성할 수 있지만:

```txt
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

```txt
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

```txt
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

```txt
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

> <b>서브쿼리는 최종 결과를 계산하기 전에 필요한 중간 표를 만드는 방법이다.</b>

그리고:

> <b>COUNT(\*)의 의미는 함수 자체가 아니라 현재 한 행이 무엇을 뜻하는지에 따라 달라진다.</b>
</details>
</details>

---
