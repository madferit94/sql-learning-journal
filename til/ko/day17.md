# Day 17 — Online Retail 월별 집계·날짜 필터·서브쿼리

[English](../en/day17.md) · [목차](../../README.ko.md)

노션 상세 기록을 바탕으로 정리한 공개본입니다. 원래 실행 결과·도움 범위를 보존했으며 이번 게시를 위해 SQL을 재실행하지 않았습니다.

### 🛒 Day17 — Online Retail 월별 집계·날짜 필터·서브쿼리
# SQL 학습 기록 — Day 17
## 학습 개요
**환경:** MySQL / retail_study / sales_items·invoice_headers
**학습 범위:** DATE_FORMAT, 연월별 집계, 날짜 범위 필터, JOIN, 서로 다른 구매 월 수, 고객별 총액 재집계.
**검증 근거:** 사용자 직접 MySQL 실행 결과. 이번 업로드를 위해 AI가 문제 쿼리를 별도 재실행하지 않았습니다. 코드의 논리는 유지하고 줄바꿈과 세미콜론을 정리했습니다.
### 접속
일반 터미널:
```bash
mysql -u root -p
```
mysql\> 화면:
```sql
USE retail_study;
SHOW TABLES;
```
이미 접속했다면 USE부터 실행합니다.
### 데이터와 한 행의 의미
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 아래는 필요한 컬럼 일부입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 연결할 주문 정보의 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| quantity | INT | 해당 상품 항목의 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |

상품 항목 금액은 quantity × unit_price입니다. 행 수·수량 합계·고유 주문 수는 서로 다릅니다.
**invoice_headers — 한 행은 주문번호·일시·고객·국가의 고유 정보 조합입니다.** 원본에서 만든 학습용 표입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 정보 조합의 고유 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

두 표는 invoice_header_id가 같으면 연결됩니다. 정보 한 행에 상품 항목 여러 행이 연결됩니다.
sales_items는 530104행이며 기간은 2010-12-01부터 2011-12-09까지입니다. 여러 연도의 같은 달을 구분해야 합니다. 원본 중복 행은 보존돼 있으므로 연습용 판매금액을 정제된 확정 매출과 동일시하지 않습니다.
invoice_headers는 고유 주문번호와 일대일이 아닐 수 있어 invoice_header_id로 연결합니다.
원본: [UCI Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail), 단가 단위 GBP.
### DATE_FORMAT 기본
DATE_FORMAT은 날짜를 지정한 형식의 문자열로 바꿉니다. %Y는 네 자리 연도, %m은 두 자리 월입니다.
```sql
DATE_FORMAT(invoice_date, '%Y-%m')
```
예: 2011-03-15 10:30:00 → 2011-03. 연월을 묶을 때 사용하며, 날짜 범위 필터에는 원래 DATETIME을 직접 비교할 수 있습니다.

### 📚 문제 1\~3 — 월별 판매·고액 비율·국가별 JOIN
## 문제 1. 월별 판매 수량과 판매금액
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 아래는 필요한 컬럼 일부입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 연결할 주문 정보의 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| quantity | INT | 해당 상품 항목의 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |

상품 항목 금액은 quantity × unit_price입니다. 행 수·수량 합계·고유 주문 수는 서로 다릅니다.
### 문제
전체 기간에서 연도와 월별 판매 수량 합계와 판매금액 합계를 조회합니다. 결과 한 행은 특정 연도의 한 달에 대한 통계입니다.
### 조건
- 연월은 YYYY-MM 형식으로 출력하고 서로 다른 연도의 같은 달을 구분합니다.
- 수량은 quantity 합계, 금액은 quantity × unit_price 합계이며 금액만 소수점 둘째 자리까지 반올림합니다.
- 고객 ID가 NULL인 기록도 포함합니다.
- 기록이 있는 연월만 출력하고 연월 오름차순 정렬합니다.
- 최소 금액·최소 수량 조건은 없으며 sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| purchase_month | 구매 연월 |
| total_quantity | 수량 합계 |
| total_sales_amount | 판매금액 합계(GBP) |

### 출력 예시 — 가상

| purchase_month | total_quantity | total_sales_amount |
| --- | --- | --- |
| 2010-12 | 1200 | 6000.00 |
| 2011-01 | 1500 | 7500.00 |
| 2011-12 | 1800 | 9000.00 |

### 예시 설명
같은 12월이어도 연도가 다르면 서로 다른 행입니다. 가상 예시이며 실제 출력은 아래에 기록합니다.
### 내 첫 시도
```sql
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS purchase_month,
    COUNT(CASE WHEN quantity * unit_price >= 1000 THEN 1 END) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FORM sales_items
GROUP BY DATE_FORMAT(invoice_date, %Y-%m) AS purchase_month
ORDER BY total_sales_amount DESC;
```
### 실행 결과·오류
ERROR 1064 (42000)가 FORM sales_items 부근에서 발생했습니다.
### 틀린 이유
FORM 오타, GROUP BY에서 날짜 형식의 따옴표와 AS 사용 오류가 있었습니다. 수량 합계에 이전 문제의 금액 조건부 COUNT가 섞였고 금액 내림차순으로 정렬했습니다. 이번 문제는 조건 없는 수량 SUM과 연월 오름차순을 요구합니다.
### 최종 쿼리
```sql
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS purchase_month,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FROM sales_items
GROUP BY purchase_month
ORDER BY purchase_month ASC;
```
### 검증

| purchase_month | total_quantity | total_sales_amount |
| --- | --- | --- |
| 2010-12 | 359239 | 823746.14 |
| 2011-01 | 387785 | 691364.56 |
| 2011-02 | 283555 | 523631.89 |
| 2011-03 | 377526 | 717639.36 |
| 2011-04 | 308815 | 537808.62 |
| 2011-05 | 395738 | 770536.02 |
| 2011-06 | 389213 | 761739.90 |
| 2011-07 | 401759 | 719221.19 |
| 2011-08 | 421770 | 759138.38 |
| 2011-09 | 570820 | 1058590.17 |
| 2011-10 | 623401 | 1154979.30 |
| 2011-11 | 754507 | 1509496.33 |
| 2011-12 | 314248 | 638792.68 |

사용자 실행: 13 rows in set (0.73 sec).
**해결 방식:** 직접 작성 → 날짜 그룹화·SUM·정렬·문법 수정 힌트 → 직접 재작성·실행.
### 핵심 개념 정리
SELECT에서 만든 purchase_month를 GROUP BY와 ORDER BY에서 사용할 수 있습니다. 같은 12월이라도 2010-12와 2011-12는 별도 그룹입니다.
---
## 문제 2. 월별 고액 상품 항목 비율
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 아래는 필요한 컬럼 일부입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 연결할 주문 정보의 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| quantity | INT | 해당 상품 항목의 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |

상품 항목 금액은 quantity × unit_price입니다. 행 수·수량 합계·고유 주문 수는 서로 다릅니다.
### 문제
전체 기간의 연월별 상품 항목 수, 100파운드 이상인 고액 항목 수, 그 비율을 조회합니다.
### 조건
- 연월은 YYYY-MM, 항목 수는 행 수입니다. 판매 수량이나 주문 수가 아닙니다.
- 항목 금액 quantity × unit_price가 정확히 100파운드인 경우도 고액입니다.
- 비율(%) = 고액 항목 수 / 전체 항목 수 × 100. 소수점 둘째 자리까지 반올림합니다.
- 고객 NULL도 포함합니다. 고액 항목이 없는 연월도 건수·비율 0으로 포함합니다.
- 기록이 있는 연월만 출력하며 최소 항목 수 조건 없이 연월 오름차순 정렬합니다.
- sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| purchase_month | 연월 |
| item_count | 전체 항목 행 수 |
| high_amount_count | 100파운드 이상 항목 수 |
| high_amount_rate | 고액 항목 비율(%) |

### 출력 예시 — 가상

| purchase_month | item_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| 2010-12 | 200 | 50 | 25.00 |
| 2011-01 | 100 | 10 | 10.00 |
| 2011-02 | 150 | 0 | 0.00 |

### 예시 설명
200행 중 50행이면 25%입니다. 수량이 20개인 한 행도 항목 수로는 1입니다. 가상 예시입니다.
### 내 첫 시도·최종 쿼리
```sql
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS purchase_month,
    COUNT(*) AS item_count,
    COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END) AS high_amount_count,
    ROUND(
        COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END)
        / COUNT(*) * 100, 2
    ) AS high_amount_rate
FROM sales_items
GROUP BY purchase_month
ORDER BY purchase_month ASC;
```
### 실행 결과·오류
첫 제출에서 집계·비율·날짜 그룹화·정렬 정답. 수정 없음.
### 검증

| purchase_month | item_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| 2010-12 | 41480 | 1056 | 2.55 |
| 2011-01 | 34306 | 794 | 2.31 |
| 2011-02 | 27105 | 764 | 2.82 |
| 2011-03 | 35803 | 1083 | 3.02 |
| 2011-04 | 29096 | 663 | 2.28 |
| 2011-05 | 36164 | 1049 | 2.90 |
| 2011-06 | 35977 | 991 | 2.75 |
| 2011-07 | 38645 | 932 | 2.41 |
| 2011-08 | 34483 | 1058 | 3.07 |
| 2011-09 | 49261 | 1340 | 2.72 |
| 2011-10 | 59304 | 1395 | 2.35 |
| 2011-11 | 83369 | 1909 | 2.29 |
| 2011-12 | 25111 | 541 | 2.15 |

사용자 실행: 13 rows in set (0.66 sec). 2010-12의 1056/41480×100은 약 2.55%입니다.
실제 출력에는 고액 0개인 월이 없었습니다. 0개인 월을 제외하지 않는 쿼리 구조와 실제 0개 사례 확인은 구분합니다.
**해결 방식:** 직접 작성 → 첫 제출 정답 → 사용자 실행 확인.
### 핵심 개념 정리
국가별로 연습한 조건부 집계·비율을 연월별 분석에 직접 적용했습니다.
---
## 문제 3. 2011년 국가별 판매 통계
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 아래는 필요한 컬럼 일부입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 연결할 주문 정보의 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| quantity | INT | 해당 상품 항목의 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |

상품 항목 금액은 quantity × unit_price입니다. 행 수·수량 합계·고유 주문 수는 서로 다릅니다.
**invoice_headers — 한 행은 주문번호·일시·고객·국가의 고유 정보 조합입니다.** 원본에서 만든 학습용 표입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 정보 조합의 고유 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

두 표는 invoice_header_id가 같으면 연결됩니다. 정보 한 행에 상품 항목 여러 행이 연결됩니다.
### 문제
두 표를 연결하여 2011년에 구매한 기록의 국가별 항목 수, 수량 합계와 판매금액을 조회합니다.
### 조건
- 구매 일시는 2011-01-01 이상, 2012-01-01 미만입니다.
- 항목 행 수가 100개 이상인 국가만 포함합니다. 수량 합계의 조건이 아닙니다.
- 수량 SUM, 항목 금액 합계는 소수점 둘째 자리까지 반올림합니다.
- 고객 NULL을 포함하고 반올림 금액 내림차순, 국가 이름 오름차순으로 정렬합니다.
- 국가·일시는 invoice_headers, 수량·단가는 sales_items에서 가져오며 두 표를 연결합니다.
**결과 한 행:** 국가 하나의 2011년 판매 통계.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 국가 |
| item_count | 항목 행 수 |
| total_quantity | 수량 합계 |
| total_sales_amount | 판매금액 합계(GBP) |

### 출력 예시 — 가상

| country | item_count | total_quantity | total_sales_amount |
| --- | --- | --- | --- |
| Country A | 200 | 1200 | 6000.00 |
| Country B | 100 | 800 | 4500.00 |

### 예시 설명
B는 수량이 1000개 미만이어도 항목이 정확히 100행이라 포함합니다. 가상 예시입니다.
### 내 첫 시도
```sql
SELECT h.country, COUNT(*) AS item_count,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(`quantity * unit_price`), 2) AS total_sales_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
GROUP BY h.country
HAVING item_count >= 100
   AND DATE_FORMAT(h.invoice_date, '%Y-%m-%d') >= 2011-01-01
   AND DATE_FORMAT(h.invoice_date, '%Y-%m-%d') < 2012-01-01
ORDER BY total_sales_amount DESC, h.country ASC;
```
원문에 섞인 붙여넣기용 역슬래시는 제외하고 표시했습니다. 별칭 total_ sales_amount의 공백은 아래 수정 이력에 남깁니다.
### 실행 결과·오류
첫 제출은 실제 오류 메시지가 공유되지 않았고 코드 검토로 수정했습니다. 날짜 조건을 옮긴 재작성 뒤에도 ORDER BY 별칭에 공백이 남아 추가 수정했습니다.
### 틀린 이유
- 날짜는 개별 기록의 조건이므로 GROUP BY 이전 WHERE에서 제한합니다.
- 날짜 리터럴에는 따옴표가 필요합니다. 원래 DATETIME에 날짜 범위를 직접 비교할 수 있습니다.
- 곱셈 전체를 백틱으로 감싸면 계산식이 아니라 그 이름의 컬럼으로 인식합니다.
- total_sales_amount 별칭의 공백을 제거했습니다.
### 최종 쿼리
```sql
SELECT h.country, COUNT(*) AS item_count,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.quantity * s.unit_price), 2) AS total_sales_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
WHERE h.invoice_date >= '2011-01-01'
  AND h.invoice_date < '2012-01-01'
GROUP BY h.country
HAVING item_count >= 100
ORDER BY total_sales_amount DESC, h.country ASC;
```
### 검증

| country | item_count | total_quantity | total_sales_amount |
| --- | --- | --- | --- |
| United Kingdom | 445899 | 4348230 | 8276953.10 |
| Netherlands | 2287 | 193550 | 276661.86 |
| EIRE | 7517 | 141403 | 273420.70 |
| Germany | 8528 | 112384 | 213626.00 |
| France | 7973 | 107114 | 200098.80 |
| Australia | 1150 | 83434 | 137488.46 |
| Spain | 2409 | 27073 | 59733.38 |
| Switzerland | 1917 | 29915 | 55784.98 |
| Belgium | 1936 | 21482 | 39386.43 |
| Sweden | 425 | 32129 | 34544.03 |
| Norway | 924 | 15754 | 32378.32 |
| Portugal | 1385 | 15274 | 31307.13 |
| Japan | 256 | 21923 | 29711.30 |
| Finland | 668 | 9450 | 21653.28 |
| Singapore | 222 | 5241 | 21279.29 |
| Channel Islands | 731 | 9411 | 20086.91 |
| Denmark | 360 | 7781 | 17673.84 |
| Italy | 718 | 7817 | 16671.74 |
| Hong Kong | 284 | 4773 | 15691.80 |
| Cyprus | 531 | 5444 | 11999.56 |
| Austria | 390 | 4830 | 9921.48 |
| Israel | 295 | 4409 | 8135.26 |
| Poland | 322 | 3544 | 7086.49 |
| Greece | 145 | 1557 | 4760.52 |
| Unspecified | 446 | 3300 | 4749.79 |
| Canada | 151 | 2763 | 3666.38 |
| Iceland | 151 | 2139 | 3598.21 |
| USA | 179 | 2458 | 3580.39 |
| Malta | 112 | 970 | 2725.59 |

사용자 실행: 29 rows in set (1.21 sec).
**해결 방식:** JOIN·집계 직접 작성 → 날짜 WHERE·리터럴·계산식·별칭 수정 피드백 → 직접 수정·실행.
### 핵심 개념 정리
WHERE는 원본 기록의 기간을 제한하고 HAVING은 국가별 집계가 끝난 항목 수를 제한합니다.


### 🧩 문제 4 — 3개월 이상 구매한 고객 수
## 문제 4. 2011년에 3개월 이상 구매한 고객 수
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 아래는 필요한 컬럼 일부입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 연결할 주문 정보의 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| quantity | INT | 해당 상품 항목의 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |

상품 항목 금액은 quantity × unit_price입니다. 행 수·수량 합계·고유 주문 수는 서로 다릅니다.
### 문제
2011년에 서로 다른 3개월 이상에 걸쳐 구매 기록이 있는 고객이 몇 명인지 조회합니다. 최종 결과 한 행은 조건을 만족한 전체 고객 수입니다.
### 조건
- 2011-01-01 이상, 2012-01-01 미만의 기록만 사용합니다.
- 고객 ID NULL은 제외합니다.
- 같은 달의 여러 구매·상품 항목은 구매 월 수로 1개월입니다.
- 정확히 3개월도 포함하며 월이 연속일 필요는 없습니다.
- 고객 목록이나 구매 월 수 합계가 아닌 고객 수를 한 행으로 출력합니다.
- 대상 고객이 없으면 0, 정렬 없음, sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_count | 서로 다른 3개월 이상 구매한 고객 수 |

### 출력 예시 — 가상

| customer_count |
| --- |
| 2 |

### 예시 설명
가상 고객 A가 1·1·3·5월, B가 2·4월, C가 3·6·12월에 구매했다면 A의 서로 다른 구매 월은 3개입니다. A·C만 포함해 2명입니다.
### 내 첫 시도
```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT COUNT(*) AS customer
    FROM sales_items
    WHERE invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
) AS count;
```
### 실행 결과·오류
첫 쿼리는 4220을 출력했습니다(1.22 sec). 안쪽이 상품 항목 행 수를 계산했고 NULL 고객 제외·3개월 조건이 없었습니다.
DISTINCT DATE_FORMAT을 반영한 두 번째 시도도 NULL 제외·HAVING이 없어 4220이었습니다(0.94 sec). 월 수를 계산하기만 하고 고객을 선별하지 않으면 바깥 행 수는 바뀌지 않습니다.
### 틀린 이유·수정 사항
서로 다른 구매 월을 세려면 일시를 연월로 바꾸고 중복을 제외해야 합니다. 고객 NULL은 WHERE, 3개월 이상은 고객별 집계 후 HAVING으로 처리합니다.
### 최종 쿼리
```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT COUNT(DISTINCT DATE_FORMAT(invoice_date, '%Y-%m')) AS purchase_month_count
    FROM sales_items
    WHERE customer_id IS NOT NULL
      AND invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
    HAVING purchase_month_count >= 3
) AS count;
```
### 검증

| customer_count |
| --- |
| 1692 |

사용자 실행: 1 row in set (0.92 sec).
**해결 방식:** 바깥 COUNT·서브쿼리 틀 직접 작성 → DISTINCT DATE_FORMAT·NULL 제외·HAVING 설명과 부분 표현 제공 → 직접 수정·실행.
### 내 말로 정리·이해 확인
사용자 질문: “왜 저기에 디스팅트 다음에 데이트 포맷”, “문제에서 is not null, distinct 등을 다 포함하고 있나”
일시 세 개가 같은 달에 두 번·다른 달 한 번이면 서로 다른 일시는 3개지만 연월은 2개입니다. DATE_FORMAT으로 월 단위 값을 만들고 DISTINCT로 반복 월을 제외한 후 COUNT합니다.
문장의 “NULL 고객 제외”는 IS NOT NULL, “서로 다른 월”·“같은 달은 한 번”은 중복 제외, “3개월 이상”은 집계 후 조건의 단서입니다. 특정 구현 하나를 강제하는 것은 아닙니다.
사용자 독립 설명이나 답 없이 재작성까지 확인한 상태는 아닙니다.


### 🧩 문제 5 — 대상 고객들의 누적 구매금액 평균
## 문제 5. 3개월 이상 구매한 고객들의 누적 구매금액 평균
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 아래는 필요한 컬럼 일부입니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 연결할 주문 정보의 ID |
| invoice_date | DATETIME | 구매 일시 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| quantity | INT | 해당 상품 항목의 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |

상품 항목 금액은 quantity × unit_price입니다. 행 수·수량 합계·고유 주문 수는 서로 다릅니다.
### 문제
2011년에 서로 다른 3개월 이상 구매한 고객 각각의 2011년 누적 구매금액을 구하고, 그 고객별 누적 금액들의 평균을 조회합니다. 고객마다 구매 월 수·항목 수가 달라도 고객 한 명당 같은 비중을 줍니다.
### 조건
- 2011-01-01 이상, 2012-01-01 미만만 사용하며 고객 NULL을 제외합니다.
- 같은 달 여러 구매는 1개월, 정확히 3개월도 포함하며 연속일 필요는 없습니다.
- 고객별 누적 금액은 그 고객의 2011년 모든 항목 금액을 합합니다.
- 고객별 금액은 중간 반올림하지 않고 최종 평균만 소수점 둘째 자리까지 반올림합니다.
- 최종 한 행, 정렬 없음, sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| avg_customer_total | 대상 고객별 2011년 누적 구매금액의 평균(GBP) |

### 출력 예시 — 가상

| avg_customer_total |
| --- |
| 1500.00 |

### 예시 설명
A는 3개월·총액 1200, B는 5개월·총액 1800, C는 2개월·총액 3000이라면 C는 제외합니다. (1200+1800)/2 = 1500입니다. 금액이 큰 C도 구매 월 조건을 만족하지 못합니다.
### 내 첫 시도
```sql
SELECT AVG(total_amount) AS avg_customer_total
FROM (
    SELECT COUNT(DISTINCT DATE_FORMAT(invoice_date, '%Y-%m')) AS purchase_month_count,
        SUM(quantity) AS total_quantity,
        ROUND(SUM(quantity * unit_price), 2) AS total_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
      AND invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
    HAVING purchase_month_count >= 3
) AS customer;
```
### 실행 결과·오류
문법 오류 없이 3915.728800을 출력했습니다(0.97 sec). 구매 월 조건·NULL·기간·합계·바깥 AVG 구조는 직접 맞췄지만 중간 합계를 반올림했고 최종 AVG는 반올림하지 않았습니다.
바깥 ROUND만 추가한 다음 실행은 3915.73(0.95 sec)이었고, 안쪽 ROUND까지 제거한 최종 실행도 3915.73(0.97 sec)이었습니다. 표시 결과가 같아도 전자는 중간 반올림 금지 조건을 만족하지 않습니다.
### 틀린 이유·수정 사항
계산에 쓰는 고객별 합계는 그대로 유지하고 표시할 최종 평균만 반올림해야 합니다. 이번 출력에 필요 없는 total_quantity는 최종본에서 제거했습니다.
### 최종 쿼리
```sql
SELECT ROUND(AVG(total_amount), 2) AS avg_customer_total
FROM (
    SELECT COUNT(DISTINCT DATE_FORMAT(invoice_date, '%Y-%m')) AS purchase_month_count,
        SUM(quantity * unit_price) AS total_amount
    FROM sales_items
    WHERE customer_id IS NOT NULL
      AND invoice_date >= '2011-01-01'
      AND invoice_date < '2012-01-01'
    GROUP BY customer_id
    HAVING purchase_month_count >= 3
) AS customer;
```
### 검증

| avg_customer_total |
| --- |
| 3915.73 |

사용자 최종 실행: 1 row in set (0.97 sec).
**해결 방식:** 두 단계 집계·월 수·기간·금액 합계 직접 구성 → 반올림 위치 피드백 → 직접 수정·실행.
### 내 말로 정리·이해 확인
실행 후 사용자 질문: “마지막 문제는 이해가 잘 안 간다.”
실행 성공과 의미 이해를 구분합니다. 설명은 아래 이해 점검에 기록하며, 사용자가 독립적으로 의미를 다시 설명한 답변은 아직 없습니다.


### 🔎 오늘 꼭 이해할 부분 — 구매 월 조건과 고객별 총액 평균
## 마지막 문제는 무엇을 묻는가?
“여러 달에 걸쳐 구매한 고객들은 2011년에 평균 얼마씩 구매했는가?”입니다.
### 1. 평균에 포함할 고객 선택
구매한 서로 다른 월이 3개 이상이어야 합니다. 3개월은 금액을 나눌 숫자가 아니라 고객을 고르는 기준입니다.

| 고객 — 가상 | 구매한 달 | 2011년 총액(GBP) | 대상 여부 |
| --- | --- | --- | --- |
| A | 1·3·5월 | 1200 | 포함 |
| B | 2·4·6·8·10월 | 1800 | 포함 |
| C | 1·2월 | 3000 | 제외 |

### 2. 선택된 고객들의 총액 평균
A·B의 총액을 더해 고객 수 2명으로 나눕니다. (1200+1800)/2 = 1500파운드. B의 구매 월이 더 많아도 고객별 총액 하나씩 같은 비중입니다.
### 실제 결과 읽기
문제 4의 대상 고객은 1692명입니다. 마지막 결과 3915.73파운드는 **이 1692명의 2011년 총구매금액을 평균 낸 고객당 금액**입니다.
월평균도, 주문당 평균도, 상품 항목당 평균도 아닙니다. 전체 대상 고객의 금액을 구매 월 수로 나누지 않습니다.
### SQL의 두 역할

| 위치 | 역할 |
| --- | --- |
| 안쪽 DISTINCT DATE_FORMAT | 고객별 서로 다른 구매 연월 수 |
| 안쪽 SUM | 고객별 2011년 모든 항목 금액 합계 |
| 안쪽 HAVING | 구매 월 3개 이상인 고객 선별 |
| 바깥 AVG | 남은 고객별 총액의 평균 |
| 바깥 ROUND | 최종 표시값 2자리 반올림 |

최종 한 행이 필요하더라도 중간 결과는 대상 고객 한 명당 한 행입니다. 이 설명은 이해를 위한 논리적 흐름이며 DB의 물리적 실행 순서를 단정하지 않습니다.
## 날짜 출력과 날짜 필터
DATE_FORMAT은 월 단위 그룹·중복 제외에 사용합니다. 특정 기간 선택은 DATETIME에 시작일 이상·다음 연도 시작일 미만을 직접 비교할 수 있습니다.
## NULL·DISTINCT 조건 읽기
문제 문장에서 NULL 제외·서로 다른·같은 달 한 번·3개 이상을 각각 표시하고, 원본 필터·중복 처리·집계 조건으로 나눠 생각합니다.


### 🧠 학습 회고·검증 범위·재풀이
## 해결 상태

| 문제 | 확인한 사용자 결과 | 도움받은 범위 |
| --- | --- | --- |
| 1 | 13행·정답 | SUM·그룹화·정렬·문법 수정 힌트 |
| 2 | 13행·첫 제출 정답 | 제출 후 수정 없음 |
| 3 | 29행·정답 | 날짜 WHERE·리터럴·백틱·별칭 수정 |
| 4 | 1692명·정답 | 서로 다른 월·NULL 제외·HAVING 설명 |
| 5 | 3915.73파운드·정답 | 반올림 위치 수정, 실행 후 의미 추가 설명 |

5문제 모두 사용자 실행 결과를 확인했습니다. 문제 5의 독립적인 의미 설명과 답 없이 재풀이는 아직 확인하지 않았습니다.
## 관찰된 진행
조건부 COUNT·비율을 연월별로 직접 적용했습니다. 서브쿼리 전체 틀은 직접 구성하지만, 무엇을 중복 제외하고 어떤 고객을 남길지 문제 조건에서 옮기는 과정은 계속 연습이 필요합니다.
## 다시 풀기 — 미실행
- [ ] 2011년에 서로 다른 4개월 이상 구매한 고객 수를 답 없이 작성
- [ ] 같은 대상 고객의 2011년 누적 구매금액 평균을 작성
- [ ] 구매 월 수가 금액의 분모가 아닌 이유를 설명
- [ ] 안쪽 한 행과 바깥 결과 한 행의 의미를 설명
**재풀이·사용자 독립 설명 확인 전까지 완료로 표시하지 않습니다.**
