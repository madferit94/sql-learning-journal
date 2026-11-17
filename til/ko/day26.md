# Day 26 — 국가별 대표 고객·CTE 대안·상위 고객 재집계

[English](../en/day26.md) · [목차](../../README.ko.md)

<details>
<summary>🛒 Day26 — 국가별 대표 고객·CTE 대안·상위 고객 재집계</summary>

# SQL 학습 기록 — Day 26

## 학습 개요

- 환경: MySQL / retail_study
- 범위: 국가·고객별 구매금액 → 대표·상위 고객 → 조건 검사·국가별 재집계
- 문제 2는 세 가지 제출 사례, 문제 3은 두 CTE·한 CTE 방식을 모두 보존합니다.
- 문제는 5개, 기록 SQL은 대안 포함 8개입니다.
- 미공유 DB 오류·결과 행·실행 시간은 추정하지 않습니다. 문제 4 수정본은 SQL만 공유됐습니다.

## 접속

일반 터미널:

```bash
/opt/homebrew/opt/mysql@8.4/bin/mysql -u root -p
```

mysql> 화면:

```sql
USE retail_study;
```

<details>
<summary>🏁 문제 1 — 국가별 대표 고객 한 명 선택</summary>

## 문제 1 — 국가별 대표 고객 한 명 선택

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

국가마다 최대 구매금액 고객 한 명을 선택합니다. ROW_NUMBER는 반올림 전 금액 내림차순·고객 ID 문자열 오름차순입니다. 출력만 소수 둘째 자리 반올림, 최종 국가 오름차순. 한 행은 국가별 대표 고객이며 출력은 country, customer_id, item_count, total_purchase_amount입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| customer_id | 고객 ID |
| item_count | 국가·고객별 내역 행 수 |
| total_purchase_amount | 고객별 구매금액, 표시만 반올림 |

### 가상 예시 — 실제 데이터 아님

가상 A국 C01·C02가 각각 1,200이면 ID가 앞선 C01만 선택합니다.

### 첫 시도·수정 대상의 핵심

```sql
ROW_NUMBER() OVER (PARTITION BY country ORDER BY purchase_amount DESC) AS total_purchase_amount
-- Outer query attempted WHERE rn = 1; the alias rn was not defined.
```

### 최종 SQL

```sql
WITH purchase_amount AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
country_ranked AS (
    SELECT country, customer_id, item_count, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM purchase_amount
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM country_ranked
WHERE rn = 1
ORDER BY country ASC;
```

### 실제 실행 결과

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Australia | 12415 | 714 | 124914.53 |
| Austria | 12360 | 129 | 2662.06 |
| Bahrain | 12355 | 13 | 459.40 |
| Belgium | 12362 | 266 | 5226.23 |
| Brazil | 12769 | 32 | 1143.60 |
| Canada | 17444 | 135 | 2940.04 |
| Channel Islands | 14936 | 364 | 8137.02 |
| Cyprus | 12359 | 248 | 6372.58 |
| Czech Republic | 12781 | 25 | 826.74 |
| Denmark | 12435 | 36 | 7829.89 |
| EIRE | 14911 | 5675 | 143825.06 |
| European Community | 15108 | 60 | 1300.25 |
| Finland | 12428 | 294 | 7956.46 |
| France | 12731 | 274 | 18895.91 |
| Germany | 12471 | 460 | 19824.05 |
| Greece | 14439 | 32 | 2661.24 |
| Iceland | 12347 | 182 | 4310.00 |
| Israel | 12688 | 171 | 4873.81 |
| Italy | 12594 | 118 | 3338.22 |
| Japan | 12753 | 197 | 21429.39 |
| Lebanon | 12764 | 45 | 1693.88 |
| Lithuania | 15332 | 35 | 1661.06 |
| Malta | 17828 | 67 | 1820.09 |
| Netherlands | 14646 | 2076 | 280206.02 |
| Norway | 12433 | 420 | 13375.87 |
| Poland | 12779 | 149 | 3981.36 |
| Portugal | 12757 | 371 | 7857.10 |
| RSA | 12446 | 57 | 1002.31 |
| Saudi Arabia | 12565 | 9 | 145.92 |

공유된 결과 하단이 없어 전체 행 수·실행 시간은 추정하지 않습니다.

### 수정 이유와 해석

첫 시도의 핵심 문제는 ROW_NUMBER에 total_purchase_amount 별칭을 붙여 금액과 번호가 섞인 점과, 두 번째 CTE에서 purchase_amount를 다음 단계로 전달하지 않은 점입니다. rn은 MySQL 예약어가 아니라 번호 컬럼의 별칭입니다. SELECT 목록에 금액을 포함하고 동점 기준을 추가했습니다. CTE를 몇 개 쓸지보다 집계→번호→선택의 의존 관계를 먼저 판단합니다.
</details>

<details>
<summary>🧩 문제 2 — 대표 고객 10,000 이상·세 가지 사례</summary>

<details>
<summary>🧩 문제 2-1 — 두 CTE·번호 계산 전 금액 필터</summary>

## 문제 2-1 — 두 CTE·번호 계산 전 금액 필터

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

국가별 최대 금액 고객 한 명 중 구매금액 10,000 이상만 조회합니다. 선택은 원래 금액 내림차순·고객 ID 문자열 오름차순입니다. 금액 조건은 원래 값으로 검사하고 출력만 둘째 자리 반올림합니다. 최종 반올림 전 금액 내림차순·국가 오름차순. 출력은 country, customer_id, item_count, total_purchase_amount이며 한 행은 조건 통과 국가의 대표 고객입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| customer_id | 고객 ID |
| item_count | 국가·고객별 내역 행 수 |
| total_purchase_amount | 고객별 구매금액, 표시만 반올림 |

### 가상 예시 — 실제 데이터 아님

가상 A국 대표 15,000·B국 대표 9,000·C국 대표 10,000이면 A·C만 포함합니다.

### 최종 SQL

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
customer_country_purchase AS (
    SELECT country, customer_id, item_count, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM country_purchase
    WHERE purchase_amount >= 10000
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM customer_country_purchase
WHERE rn = 1
ORDER BY purchase_amount DESC, country ASC;
```

### 실제 실행 결과

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Netherlands | 14646 | 2076 | 280206.02 |
| United Kingdom | 18102 | 431 | 259657.30 |
| EIRE | 14911 | 5675 | 143825.06 |
| Australia | 12415 | 714 | 124914.53 |
| Sweden | 17404 | 198 | 31906.82 |
| Japan | 12753 | 197 | 21429.39 |
| Singapore | 12744 | 222 | 21279.29 |
| Germany | 12471 | 460 | 19824.05 |
| France | 12731 | 274 | 18895.91 |
| Spain | 12540 | 478 | 13400.24 |
| Norway | 12433 | 420 | 13375.87 |
| Switzerland | 12409 | 109 | 11072.67 |

12 rows in set (2.89 sec)

### 수정 이유와 해석

두 번째 CTE의 WHERE는 적용됩니다. 이번에는 최대 금액을 선택하며 같은 금액의 하한을 검사하므로 순위 전에 10,000 미만을 제외해도 대표 선택 후 검사와 동등합니다. 날짜로 대표 거래를 고르고 금액을 검사한 금융 문제와는 다릅니다. 최종 정렬은 반올림 출력 별칭이 아니라 원래 purchase_amount로 수정했습니다.
</details>

<details>
<summary>🧩 문제 2-2 — 두 CTE·안팎 중복 금액 조건</summary>

## 문제 2-2 — 두 CTE·안팎 중복 금액 조건

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

문제 2의 같은 대표 고객·경계값·동점·정렬 조건을 유지합니다. 두 번째 CTE와 바깥 WHERE에 같은 10,000 이상 조건을 모두 둔 제출 사례입니다. 출력은 country, customer_id, item_count, total_purchase_amount입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| customer_id | 고객 ID |
| item_count | 국가·고객별 내역 행 수 |
| total_purchase_amount | 고객별 구매금액, 표시만 반올림 |

### 가상 예시 — 실제 데이터 아님

같은 가상 예시에서 중복 조건을 추가해도 포함 대상은 같습니다.

### 최종 SQL

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
customer_country_purchase AS (
    SELECT country, customer_id, item_count, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM country_purchase
    WHERE purchase_amount >= 10000
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM customer_country_purchase
WHERE rn = 1 AND purchase_amount >= 10000
ORDER BY purchase_amount DESC, country ASC;
```

### 실제 실행 결과

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Netherlands | 14646 | 2076 | 280206.02 |
| United Kingdom | 18102 | 431 | 259657.30 |
| EIRE | 14911 | 5675 | 143825.06 |
| Australia | 12415 | 714 | 124914.53 |
| Sweden | 17404 | 198 | 31906.82 |
| Japan | 12753 | 197 | 21429.39 |
| Singapore | 12744 | 222 | 21279.29 |
| Germany | 12471 | 460 | 19824.05 |
| France | 12731 | 274 | 18895.91 |
| Spain | 12540 | 478 | 13400.24 |
| Norway | 12433 | 420 | 13375.87 |
| Switzerland | 12409 | 109 | 11072.67 |

12 rows in set (0.84 sec)

### 수정 이유와 해석

안쪽에서 이미 10,000 미만을 제외했으므로 바깥의 같은 금액 조건은 결과에 영향을 주지 않습니다. 정답이지만 중복 조건입니다. 2.89초·0.84초 각 한 번 실행만으로 성능 우열을 결론내리지 않습니다.
</details>

<details>
<summary>🧩 문제 2-3 — 한 CTE·집계와 번호 계산 통합</summary>

## 문제 2-3 — 한 CTE·집계와 번호 계산 통합

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

문제 2의 같은 대표 고객·경계값·동점·정렬 조건을 유지합니다. 한 CTE에서 집계·HAVING·ROW_NUMBER를 함께 쓰는 제출 사례입니다. 출력은 country, customer_id, item_count, total_purchase_amount입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| customer_id | 고객 ID |
| item_count | 국가·고객별 내역 행 수 |
| total_purchase_amount | 고객별 구매금액, 표시만 반올림 |

### 가상 예시 — 실제 데이터 아님

같은 가상 예시를 한 CTE로 표현해도 A·C가 포함됩니다.

### 최종 SQL

```sql
WITH ranked_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY SUM(quantity * unit_price) DESC, customer_id ASC
           ) AS rn
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
    HAVING SUM(quantity * unit_price) >= 10000
)
SELECT country, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM ranked_purchase
WHERE rn = 1
ORDER BY purchase_amount DESC, country ASC;
```

### 실제 실행 결과

| country | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- |
| Netherlands | 14646 | 2076 | 280206.02 |
| United Kingdom | 18102 | 431 | 259657.30 |
| EIRE | 14911 | 5675 | 143825.06 |
| Australia | 12415 | 714 | 124914.53 |
| Sweden | 17404 | 198 | 31906.82 |
| Japan | 12753 | 197 | 21429.39 |
| Singapore | 12744 | 222 | 21279.29 |
| Germany | 12471 | 460 | 19824.05 |
| France | 12731 | 274 | 18895.91 |
| Spain | 12540 | 478 | 13400.24 |
| Norway | 12433 | 420 | 13375.87 |
| Switzerland | 12409 | 109 | 11072.67 |

12 rows in set (1.23 sec)

### 수정 이유와 해석

GROUP BY·SUM 뒤 HAVING으로 합계 하한을 적용하고 ROW_NUMBER로 번호를 계산할 수 있습니다. 같은 SELECT의 purchase_amount 별칭 대신 SUM(quantity * unit_price)를 창 정렬에 직접 사용했습니다. 마지막 정렬은 원래 금액입니다. 두 CTE가 필수는 아닙니다.
</details>
</details>

<details>
<summary>🏁 문제 3 — 공동 2위까지·두 CTE와 한 CTE</summary>

<details>
<summary>🧩 문제 3-1 — 두 CTE·국가별 공동 2위까지</summary>

## 문제 3-1 — 두 CTE·국가별 공동 2위까지

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

국가별 구매금액 RANK 2위 이내를 모두 출력합니다. 10,000 조건은 없습니다. 반올림 전 금액만으로 공동 순위를 계산하고 다음 순위는 건너뜁니다. 공동 2위 모두 포함해 국가당 2명을 넘을 수 있습니다. 출력만 둘째 자리 반올림. 국가·country_rank·고객 ID 모두 오름차순. 출력은 country, country_rank, customer_id, item_count, total_purchase_amount이며 한 행은 통과 국가·고객입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| country_rank | 국가 내 공동 순위 |
| customer_id | 고객 ID |
| item_count | 국가·고객별 내역 행 수 |
| total_purchase_amount | 고객별 구매금액, 표시만 반올림 |

### 가상 예시 — 실제 데이터 아님

가상 한 국가 15,000·12,000·12,000이면 순위 1·2·2의 세 고객을 포함합니다.

### 첫 시도·수정 대상의 핵심

```sql
-- Two-CTE RANK version was correct on submission.
```

### 최종 SQL

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
purchase_rank AS (
    SELECT country,
           RANK() OVER (PARTITION BY country ORDER BY purchase_amount DESC) AS country_rank,
           customer_id, item_count,
           ROUND(purchase_amount, 2) AS total_purchase_amount
    FROM country_purchase
)
SELECT country, country_rank, customer_id, item_count, total_purchase_amount
FROM purchase_rank
WHERE country_rank <= 2
ORDER BY country ASC, country_rank ASC, customer_id ASC;
```

### 실제 실행 결과

| country | country_rank | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- | --- |
| Australia | 1 | 12415 | 714 | 124914.53 |
| Australia | 2 | 12431 | 181 | 5514.67 |
| Austria | 1 | 12360 | 129 | 2662.06 |
| Austria | 2 | 12865 | 95 | 1568.23 |
| Bahrain | 1 | 12355 | 13 | 459.40 |
| Bahrain | 2 | 12353 | 4 | 89.00 |
| Belgium | 1 | 12362 | 266 | 5226.23 |
| Belgium | 2 | 12449 | 191 | 4067.29 |
| Brazil | 1 | 12769 | 32 | 1143.60 |
| Canada | 1 | 17444 | 135 | 2940.04 |
| Canada | 2 | 17443 | 1 | 534.24 |
| Channel Islands | 1 | 14936 | 364 | 8137.02 |
| Channel Islands | 2 | 14930 | 128 | 2372.86 |
| Cyprus | 1 | 12359 | 248 | 6372.58 |
| Cyprus | 2 | 12370 | 159 | 3268.49 |
| Czech Republic | 1 | 12781 | 25 | 826.74 |
| Denmark | 1 | 12435 | 36 | 7829.89 |
| Denmark | 2 | 12406 | 105 | 3415.30 |
| EIRE | 1 | 14911 | 5675 | 143825.06 |
| EIRE | 2 | 14156 | 1400 | 117379.63 |
| European Community | 1 | 15108 | 60 | 1300.25 |
| Finland | 1 | 12428 | 294 | 7956.46 |
| Finland | 2 | 12664 | 37 | 4881.88 |
| France | 1 | 12731 | 274 | 18895.91 |
| France | 2 | 12678 | 165 | 17628.46 |
| Germany | 1 | 12471 | 460 | 19824.05 |

공유된 앞부분 26행만 수록합니다. 전체 행 수·실행 시간은 미공유입니다.

### 수정 이유와 해석

반올림 전 금액으로 RANK를 계산하고 화면 금액만 반올림했습니다. 고객 ID는 순위에 넣지 않고 마지막 표시 정렬에만 사용해 공동 순위를 보존했습니다. 출력 일부만 공유되어 미공유 행 수·시간은 추정하지 않습니다.
</details>

<details>
<summary>🧩 문제 3-2 — 한 CTE·집계와 RANK 통합</summary>

## 문제 3-2 — 한 CTE·집계와 RANK 통합

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

문제 3의 같은 공동 순위·금액·정렬 조건을 유지합니다. 한 CTE에 집계와 RANK를 합친 대안입니다. 출력은 country, country_rank, customer_id, item_count, total_purchase_amount입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| country_rank | 국가 내 공동 순위 |
| customer_id | 고객 ID |
| item_count | 국가·고객별 내역 행 수 |
| total_purchase_amount | 고객별 구매금액, 표시만 반올림 |

### 가상 예시 — 실제 데이터 아님

같은 가상 동점 예시를 한 CTE로 표현해도 세 고객을 포함합니다.

### 최종 SQL

```sql
WITH ranked_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount,
           RANK() OVER (
               PARTITION BY country
               ORDER BY SUM(quantity * unit_price) DESC
           ) AS country_rank
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
)
SELECT country, country_rank, customer_id, item_count,
       ROUND(purchase_amount, 2) AS total_purchase_amount
FROM ranked_purchase
WHERE country_rank <= 2
ORDER BY country ASC, country_rank ASC, customer_id ASC;
```

### 실제 실행 결과

| country | country_rank | customer_id | item_count | total_purchase_amount |
| --- | --- | --- | --- | --- |
| Australia | 1 | 12415 | 714 | 124914.53 |
| Australia | 2 | 12431 | 181 | 5514.67 |
| Austria | 1 | 12360 | 129 | 2662.06 |
| Austria | 2 | 12865 | 95 | 1568.23 |
| Bahrain | 1 | 12355 | 13 | 459.40 |
| Bahrain | 2 | 12353 | 4 | 89.00 |
| Belgium | 1 | 12362 | 266 | 5226.23 |
| Belgium | 2 | 12449 | 191 | 4067.29 |
| Brazil | 1 | 12769 | 32 | 1143.60 |
| Canada | 1 | 17444 | 135 | 2940.04 |
| Canada | 2 | 17443 | 1 | 534.24 |
| Channel Islands | 1 | 14936 | 364 | 8137.02 |
| Channel Islands | 2 | 14930 | 128 | 2372.86 |
| Cyprus | 1 | 12359 | 248 | 6372.58 |
| Cyprus | 2 | 12370 | 159 | 3268.49 |
| Czech Republic | 1 | 12781 | 25 | 826.74 |
| Denmark | 1 | 12435 | 36 | 7829.89 |
| Denmark | 2 | 12406 | 105 | 3415.30 |
| EIRE | 1 | 14911 | 5675 | 143825.06 |
| EIRE | 2 | 14156 | 1400 | 117379.63 |
| European Community | 1 | 15108 | 60 | 1300.25 |
| Finland | 1 | 12428 | 294 | 7956.46 |
| Finland | 2 | 12664 | 37 | 4881.88 |
| France | 1 | 12731 | 274 | 18895.91 |
| France | 2 | 12678 | 165 | 17628.46 |
| Germany | 1 | 12471 | 460 | 19824.05 |
| Germany | 2 | 12621 | 467 | 13689.67 |
| Greece | 1 | 14439 | 32 | 2661.24 |
| Greece | 2 | 12717 | 55 | 1030.98 |
| Iceland | 1 | 12347 | 182 | 4310.00 |
| Israel | 1 | 12688 | 171 | 4873.81 |
| Israel | 2 | 12653 | 43 | 2209.85 |
| Italy | 1 | 12594 | 118 | 3338.22 |
| Italy | 2 | 12578 | 114 | 2794.51 |
| Japan | 1 | 12753 | 197 | 21429.39 |
| Japan | 2 | 12798 | 8 | 6977.04 |
| Lebanon | 1 | 12764 | 45 | 1693.88 |
| Lithuania | 1 | 15332 | 35 | 1661.06 |
| Malta | 1 | 17828 | 67 | 1820.09 |
| Malta | 2 | 15480 | 45 | 905.50 |
| Netherlands | 1 | 14646 | 2076 | 280206.02 |
| Netherlands | 2 | 12759 | 95 | 1531.44 |
| Norway | 1 | 12433 | 420 | 13375.87 |
| Norway | 2 | 12432 | 108 | 5059.32 |
| Poland | 1 | 12779 | 149 | 3981.36 |
| Poland | 2 | 12576 | 88 | 1315.83 |
| Portugal | 1 | 12757 | 371 | 7857.10 |
| Portugal | 2 | 12766 | 310 | 6989.63 |
| RSA | 1 | 12446 | 57 | 1002.31 |
| Saudi Arabia | 1 | 12565 | 9 | 145.92 |
| Singapore | 1 | 12744 | 222 | 21279.29 |
| Spain | 1 | 12540 | 478 | 13400.24 |
| Spain | 2 | 12557 | 33 | 11990.96 |
| Sweden | 1 | 17404 | 198 | 31906.82 |
| Sweden | 2 | 12483 | 75 | 2484.98 |
| Switzerland | 1 | 12409 | 109 | 11072.67 |
| Switzerland | 2 | 12451 | 354 | 9035.52 |
| USA | 1 | 12607 | 101 | 1579.51 |
| USA | 2 | 12646 | 45 | 1346.97 |
| United Arab Emirates | 1 | 12739 | 38 | 1013.04 |
| United Arab Emirates | 2 | 17829 | 30 | 889.24 |
| United Kingdom | 1 | 18102 | 431 | 259657.30 |
| United Kingdom | 2 | 17450 | 337 | 194550.79 |
| Unspecified | 1 | 16320 | 56 | 1038.46 |
| Unspecified | 2 | 12363 | 23 | 552.00 |

65 rows in set (2.47 sec)

### 수정 이유와 해석

제공된 한 CTE 대안 SQL을 실행한 결과입니다. 집계와 RANK를 한 단계에 쓰되 계산한 순위의 필터는 바깥 SELECT로 분리합니다. 두 CTE 방식과 같은 논리의 대안으로 함께 보존합니다.
</details>
</details>

<details>
<summary>🏁 문제 4 — 국가별 최대 2명 선택</summary>

## 문제 4 — 국가별 최대 2명 선택

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

국가별 최대 2명을 ROW_NUMBER로 선택합니다. 10,000 조건은 없습니다. 원래 금액 내림차순·고객 ID 문자열 오름차순으로 번호를 부여합니다. 1·2번만 선택하며 대상 한 명이면 한 명만 출력합니다. 표시 금액만 둘째 자리 반올림. 국가·selection_no 오름차순. 출력은 country, selection_no, customer_id, item_count, total_purchase_amount입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| selection_no | 국가 내 고유 선택 번호 |
| customer_id | 고객 ID |
| item_count | 국가·고객별 내역 행 수 |
| total_purchase_amount | 고객별 구매금액, 표시만 반올림 |

### 가상 예시 — 실제 데이터 아님

가상 C01 15,000·C02 12,000·C03 12,000이면 C01·C02만 선택합니다.

### 첫 시도·수정 대상의 핵심

```sql
RANK() OVER (PARTITION BY country ORDER BY purchase_amount DESC) AS country_rank
-- This keeps boundary ties and does not enforce at most two.
```

### 최종 SQL

```sql
WITH country_purchase AS (
    SELECT country, customer_id, COUNT(*) AS item_count,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
purchase_rank AS (
    SELECT country,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS selection_no,
           customer_id, item_count,
           ROUND(purchase_amount, 2) AS total_purchase_amount
    FROM country_purchase
)
SELECT country, selection_no, customer_id, item_count, total_purchase_amount
FROM purchase_rank
WHERE selection_no <= 2
ORDER BY country ASC, selection_no ASC;
```

### 실제 실행 결과

최종 수정본 출력이 공유되지 않아 결과표를 만들지 않습니다.

최종 수정 SQL만 공유됐습니다. 실제 결과표·실행 시간은 미공유입니다.

### 수정 이유와 해석

처음 RANK를 사용해 공동 2위가 여러 명이면 인원이 늘어날 수 있었습니다. ROW_NUMBER와 고객 ID 동점 기준으로 바꾸고 별칭·필터·최종 정렬을 selection_no로 맞췄습니다. 최종 SQL은 조건에 맞지만 수정본 출력은 공유되지 않아 사용자 실행 확인으로 표시하지 않습니다.
</details>

<details>
<summary>🧩 문제 5 — 선택한 상위 2명의 국가별 재집계</summary>

## 문제 5 — 선택한 상위 2명의 국가별 재집계

### 테이블과 한 행의 의미

sales_items는 판매 내역 뷰이며 한 행은 송장 상품 내역 한 줄입니다. 주문 한 건이나 상품 한 개와 다릅니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT | 원본 행 식별자, NULL 불가 |
| country | VARCHAR(100) | 구매 기록의 국가, NULL 불가 |
| customer_id | VARCHAR(20) | 고객 ID, NULL은 고객 미확인 |
| quantity | INT | 구매 수량, NULL 불가 |
| unit_price | DECIMAL(16,6) | 단가, GBP·NULL 불가 |

뷰는 quantity > 0, unit_price > 0이고 invoice_no가 C로 시작하지 않는 내역입니다. 반품·취소 차감 순매출과 구분합니다. 구매 기록의 국가는 고객의 고정 거주국으로 단정하지 않습니다.

### 문제와 조건

sales_items만 사용하며 전체 기간을 대상으로 합니다. customer_id NULL은 제외하고 국가·고객 조합으로 집계합니다. 구매금액은 SUM(quantity * unit_price), item_count는 내역 행 수입니다. 고객이 여러 국가에 나타나면 분리합니다.

국가마다 원래 구매금액 내림차순·고객 ID 문자열 오름차순으로 최대 2명을 선택한 다음, 선택 인원과 그들의 금액 합계를 국가별로 조회합니다. ROW_NUMBER 사용, 10,000 조건 없음. 대상 한 명인 국가는 한 명만 합산합니다. 고객별 금액을 반올림하지 않고 더한 뒤 최종 합계만 둘째 자리 반올림합니다. 반올림 전 합계 내림차순·국가 오름차순. 출력은 country, selected_customer_count, top2_purchase_amount이며 한 행은 국가별 요약입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 구매 기록의 국가 |
| selected_customer_count | 선택된 고객 수 |
| top2_purchase_amount | 선택 고객들의 금액 합계 |

### 가상 예시 — 실제 데이터 아님

가상 A국 C01 15,000·C02 12,000·C03 12,000이면 C01·C02의 27,000을 합산하고 2명을 셉니다. B국에 9,000인 한 명뿐이면 1명·9,000입니다.

### 첫 시도·수정 대상의 핵심

```sql
COUNT(*) AS selected_customer_count
-- Inside GROUP BY country, customer_id this counts item lines, not selected customers.
COUNT(SUM(quantity * unit_price)) AS selected_customer_count
-- Nested aggregate at one query level cannot express the required country summary.
```

### 최종 SQL

```sql
WITH customer_purchase AS (
    SELECT country, customer_id,
           SUM(quantity * unit_price) AS purchase_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY country, customer_id
),
rn_customer AS (
    SELECT country, customer_id, purchase_amount,
           ROW_NUMBER() OVER (
               PARTITION BY country
               ORDER BY purchase_amount DESC, customer_id ASC
           ) AS rn
    FROM customer_purchase
)
SELECT country,
       COUNT(*) AS selected_customer_count,
       ROUND(SUM(purchase_amount), 2) AS top2_purchase_amount
FROM rn_customer
WHERE rn <= 2
GROUP BY country
ORDER BY SUM(purchase_amount) DESC, country ASC;
```

### 실제 실행 결과

| country | selected_customer_count | top2_purchase_amount |
| --- | --- | --- |
| United Kingdom | 2 | 454208.09 |
| Netherlands | 2 | 281737.46 |
| EIRE | 2 | 261204.69 |
| Australia | 2 | 130429.20 |
| France | 2 | 36524.37 |
| Sweden | 2 | 34391.80 |
| Germany | 2 | 33513.72 |
| Japan | 2 | 28406.43 |
| Spain | 2 | 25391.20 |
| Singapore | 1 | 21279.29 |
| Switzerland | 2 | 20108.19 |
| Norway | 2 | 18435.19 |
| Portugal | 2 | 14846.73 |
| Finland | 2 | 12838.34 |
| Denmark | 2 | 11245.19 |
| Channel Islands | 2 | 10509.88 |
| Cyprus | 2 | 9641.07 |
| Belgium | 2 | 9293.52 |
| Israel | 2 | 7083.66 |
| Italy | 2 | 6132.73 |
| Poland | 2 | 5297.19 |
| Iceland | 1 | 4310.00 |
| Austria | 2 | 4230.29 |
| Greece | 2 | 3692.22 |
| Canada | 2 | 3474.28 |
| USA | 2 | 2926.48 |
| Malta | 2 | 2725.59 |
| United Arab Emirates | 2 | 1902.28 |
| Lebanon | 1 | 1693.88 |
| Lithuania | 1 | 1661.06 |
| Unspecified | 2 | 1590.46 |
| European Community | 1 | 1300.25 |
| Brazil | 1 | 1143.60 |
| RSA | 1 | 1002.31 |
| Czech Republic | 1 | 826.74 |
| Bahrain | 2 | 548.40 |
| Saudi Arabia | 1 | 145.92 |

37 rows in set (2.43 sec)

### 수정 이유와 해석

처음 고객별 COUNT를 고객 수로 해석하고, 합계와 개수를 COUNT(SUM(...))로 한 단계에 섞었습니다. 번호 계산 단계에서 금액을 전달하지 않거나, 계산 중 같은 단계에서 rn을 필터링하려는 시도도 있었습니다. 마지막에는 고객별 금액→번호→상위 2명 선택→국가별 재집계로 분리했습니다. 반올림은 최종 합계에만 적용합니다.
</details>

<details>
<summary>🔎 이해 정리·복습 — 고객별 집계에서 국가별 집계로</summary>

## 문제 5 다시 이해하기 — 작은 가상 표

아래는 실제 데이터가 아닌 이해용 예시입니다.

### 1단계: 고객별 금액 만들기

| country | customer_id | purchase_amount |
| --- | --- | --- |
| A국 | C01 | 15000 |
| A국 | C02 | 12000 |
| A국 | C03 | 12000 |
| B국 | C04 | 9000 |

customer_purchase의 한 행은 국가·고객 한 조합입니다. 원본 거래가 여러 줄이어도 이 단계에서 고객별 한 행으로 합쳐집니다.

### 2단계: 행을 유지하고 번호만 붙이기

| country | customer_id | purchase_amount | rn |
| --- | --- | --- | --- |
| A국 | C01 | 15000 | 1 |
| A국 | C02 | 12000 | 2 |
| A국 | C03 | 12000 | 3 |
| B국 | C04 | 9000 | 1 |

번호를 붙이는 단계는 고객 수를 세는 단계가 아닙니다. 12,000 동점에서 고객 ID가 앞선 C02가 먼저입니다. 이후 rn <= 2로 C03을 제외합니다.

### 3단계: 선택된 고객 행을 국가별로 다시 묶기

| country | selected_customer_count | top2_purchase_amount |
| --- | --- | --- |
| A국 | 2 | 27000 |
| B국 | 1 | 9000 |

마지막 COUNT(*)는 남은 고객 행을 세므로 고객 수입니다. SUM(purchase_amount)는 이미 만들어진 고객별 금액을 더합니다. A국은 15,000 + 12,000 = 27,000입니다.

원본에서 COUNT(*)를 하면 내역 줄 수, 고객별 집계표에서 COUNT(*)를 하면 고객 수가 됩니다. 함수가 바뀐 것이 아니라 세는 표의 한 행 의미가 바뀐 것입니다.

## 복습

- [ ] SELECT에 전달하지 않은 컬럼을 다음 CTE에서 사용할 수 없는 이유 설명하기
- [ ] 최대값 선택과 그 값의 하한 필터가 이번에 교환 가능한 이유 설명하기
- [ ] RANK와 ROW_NUMBER로 경계 동점을 다루는 차이 설명하기
- [ ] 번호 부여 단계에서 COUNT를 하지 않는 이유 설명하기
- [ ] 상위 고객 선택 후 국가별 재집계 한 문제를 독립 재풀이하기

다음 독립 재풀이는 아직 확인하지 않았습니다.
</details>
</details>