# Day 16 — 2026-10-15 to 2026-10-16

[English](../en/day16.md) · [목차](../../README.ko.md)

노션의 상세 기록을 공개용으로 정리했습니다. SQL·실행 결과는 당시 기록이며 게시를 위해 재실행하지 않았습니다. 거래 연습 데이터의 식별자는 가명 처리했습니다.

# SQL 학습 기록 — Day 16
## E-commerce SQL — Online Retail (2026-10-15~2026-10-16)
**학습 기간:** 2026-10-15 to 2026-10-16
**정리일:** 2026-10-16
**환경:** MySQL / retail_study / sales_items·invoice_headers
**번호 근거:** 기존 최신 Day15(2026-10-13) 뒤에 이어진 5문제 학습 묶음을 Day16으로 기록합니다. 이 묶음은 15\~16일에 나누어 진행했으며, 학습 세션 번호와 달력 날짜를 구분합니다.
**진행 날짜:** 10월14일은 새 데이터 적재·접속 확인 후 문제 풀이를 미뤘습니다. 10월15일 P1 실행, 10월16일 P2\~P5 실행을 확인했습니다. 미실행 복습 계획을 완료로 기록하지 않습니다.
**검증 근거:** 사용자가 직접 공유한 MySQL 결과. 이번 업로드에서 AI가 문제 쿼리를 재실행하지 않았습니다. SQL은 제출 논리를 유지하고 줄바꿈·세미콜론·대소문자 표시만 정리했습니다.
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
이미 접속했다면 USE부터 실행합니다. 터미널 % 화면에는 SQL을 입력하지 않습니다.
### 데이터와 한 행의 의미

| 표·뷰 | 한 행의 의미 | 행 수 |
| --- | --- | --- |
| invoice_items | 원본 상품 항목 한 행 | 541909 |
| invoice_headers | 주문번호·일시·고객·국가의 고유 조합 | 25943 |
| sales_items | 양수 수량·단가의 비취소 원본 상품 항목 | 530104 |

고유 주문번호는 25900개입니다. 43개 주문번호 안에서 일시·고객·국가 조합이 달라 invoice_headers는 25943행으로 만들었습니다. 헤더 행 수를 고유 주문 수라고 부르지 않습니다.
JOIN에는 invoice_header_id를 사용합니다. 원본 중복 추가분 5268행과 NULL·음수 기록은 invoice_items에 보존했습니다. sales_items에도 중복과 고객 NULL이 남아 있습니다.
원본 customer_id NULL은 135080행이고 sales_items 중 고객 NULL 기록은 132220행입니다. 고객 ID를 모르는 기록을 고객 한 명으로 취급하지 않습니다.
원본: [UCI Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail), Daqing Chen, 2015, DOI 10.24432/C5BW33, CC BY 4.0. 기간 2010-12-01\~2011-12-09, 단가 단위 GBP.
기존 Olist는 사용자 요청에 따라 백업 후 삭제했고 새 retail_study를 적재·검증했습니다. F1·finance·soccer는 유지했습니다. 문제의 구매금액·판매금액은 연습용 정의로, 원본 취소·조정·중복을 정리한 확정 매출을 뜻하지 않습니다.

### 📚 문제 1\~3 — 국가별 판매·고액 비율·고객 JOIN
## P1 / 5 — 국가별 판매 수량과 판매금액
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 원본 중복 행은 제거하지 않았습니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| source_row_id | INT | 원본 상품 항목 행의 고유 번호 |
| invoice_header_id | INT | JOIN용 주문 정보 조합 ID |
| invoice_no | VARCHAR(20) | 원본 주문번호, 여러 상품 행에서 반복 가능 |
| quantity | INT | 해당 항목의 판매 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

위는 필요한 주요 컬럼 일부입니다. 상품 항목 금액은 quantity × unit_price입니다. 수량 6개·단가 2.55이면 한 행의 금액은 15.30파운드이며, 행 수는 1입니다.
### 문제
sales_items에서 국가별 판매 수량과 판매금액을 조회하는 SQL문을 작성하세요. 결과 한 행은 국가 하나의 판매 통계입니다.
### 조건
- 전체 기간을 사용합니다.
- 국가별 판매 수량 합계가 1,000개 이상인 국가만 출력합니다. 정확히 1,000개도 포함합니다.
- 판매금액은 각 행의 quantity × unit_price를 합하고 최종 소수점 둘째 자리까지 반올림합니다.
- 고객 ID가 NULL인 기록도 포함합니다.
- 반올림한 금액 내림차순, 같으면 국가 이름 오름차순. sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 국가 |
| total_quantity | 수량 합계 |
| total_sales_amount | 상품 항목 금액 합계(GBP) |

### 출력 예시 — 가상

| country | total_quantity | total_sales_amount |
| --- | --- | --- |
| Country A | 1200 | 6000.00 |
| Country B | 1000 | 4500.00 |

### 예시 설명
상품 항목의 행 수가 아닌 수량을 합합니다. B는 수량이 정확히 1,000개라 포함됩니다.
예시는 이해를 위한 가상 결과입니다. 실제 사용자 실행 결과는 아래 검증 항목에 따로 기록합니다.
### 내 첫 시도·최종 쿼리
```sql
SELECT country, SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales_amount
FROM sales_items
GROUP BY country
HAVING total_quantity >= 1000
ORDER BY total_sales_amount DESC, country ASC;
```
### 실행 결과·오류
2026-10-15 첫 제출에서 집계·조건·정렬 정답. 수정 없음.
### 검증 — 사용자 실제 출력 전체

| country | total_quantity | total_sales_amount |
| --- | --- | --- |
| United Kingdom | 4662390 | 9025222.08 |
| Netherlands | 200361 | 285446.34 |
| EIRE | 147173 | 283453.96 |
| Germany | 119261 | 228867.14 |
| France | 112103 | 209715.11 |
| Australia | 83901 | 138521.31 |
| Spain | 27940 | 61577.11 |
| Switzerland | 30629 | 57089.90 |
| Belgium | 23237 | 41196.34 |
| Sweden | 36083 | 38378.33 |
| Japan | 26016 | 37416.37 |
| Norway | 19336 | 36165.44 |
| Portugal | 16258 | 33747.10 |
| Finland | 10704 | 22546.08 |
| Singapore | 5241 | 21279.29 |
| Channel Islands | 9491 | 20450.44 |
| Denmark | 8235 | 18955.34 |
| Italy | 8112 | 17483.24 |
| Hong Kong | 4773 | 15691.80 |
| Cyprus | 6361 | 13590.38 |
| Austria | 4881 | 10198.68 |
| Israel | 4409 | 8135.26 |
| Poland | 3684 | 7334.65 |
| Greece | 1557 | 4760.52 |
| Unspecified | 3300 | 4749.79 |
| Iceland | 2458 | 4310.00 |
| Canada | 2763 | 3666.38 |
| USA | 2458 | 3580.39 |

28 rows in set (1.54 sec).
**해결 방식:** 직접 작성 → 첫 제출 정답 → 사용자 실행 확인.
### 내 말로 정리
건수는 행 수이고, 수량 합계는 quantity를 더한 값이다. 각 행에서 수량×단가를 계산한 뒤 국가별로 합한다.
---
## P2 / 5 — 국가별 고액 상품 항목 비율
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 원본 중복 행은 제거하지 않았습니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| source_row_id | INT | 원본 상품 항목 행의 고유 번호 |
| invoice_header_id | INT | JOIN용 주문 정보 조합 ID |
| invoice_no | VARCHAR(20) | 원본 주문번호, 여러 상품 행에서 반복 가능 |
| quantity | INT | 해당 항목의 판매 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

위는 필요한 주요 컬럼 일부입니다. 상품 항목 금액은 quantity × unit_price입니다. 수량 6개·단가 2.55이면 한 행의 금액은 15.30파운드이며, 행 수는 1입니다.
### 문제
상품 항목이 100행 이상 기록된 국가의 이름, 전체 상품 항목 수, 고액 항목 수와 고액 항목 비율을 조회하세요. 고액 항목은 quantity × unit_price가 100파운드 이상인 행입니다.
### 조건
- 전체 기간을 사용하며 수량 합계가 아닌 상품 항목 행 수 100개 이상으로 국가를 선별합니다.
- 정확히 100파운드인 항목도 고액에 포함합니다.
- 비율(%) = 고액 항목 수 / 전체 상품 항목 수 × 100. 최종 소수점 둘째 자리까지 반올림합니다.
- 고액 항목이 없어도 전체 행 수 조건을 만족하면 포함하며 건수·비율은 0입니다.
- 반올림 비율 내림차순, 같으면 국가 이름 오름차순. sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| country | 국가 |
| item_count | 상품 항목 행 수 |
| high_amount_count | 100파운드 이상인 항목 수 |
| high_amount_rate | 고액 항목 비율(%) |

### 출력 예시 — 가상

| country | item_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| Country A | 200 | 50 | 25.00 |
| Country B | 100 | 10 | 10.00 |
| Country C | 150 | 0 | 0.00 |

### 예시 설명
A는 200행 중 50행이 고액이라 25%입니다. 수량이 20개인 한 행도 항목 수로는 1입니다. C는 0개여도 포함됩니다.
예시는 이해를 위한 가상 결과입니다. 실제 사용자 실행 결과는 아래 검증 항목에 따로 기록합니다.
### 내 첫 시도
```sql
SELECT, country, COUNT(*) AS item_count,
    COUNT(CASE WHEN unit_price >= 100 THEN 1 END) AS high_amount_count,
    ROUND(COUNT(CASE WHEN unit_price >= 100 THEN 1 END)
        / COUNT(*) * 100, 2) AS high_amount_rate
FROM sales_item
GROUP BY country
HAVING item_count >= 100
ORDER BY high_amount_rate DESC, country ASC;
```
### 실행 결과·오류
첫 코드의 실제 오류 메시지는 제출되지 않았습니다. SELECT 뒤 쉼표, sales_item 표 이름, 단가만 비교한 조건을 코드 검토에서 확인했습니다.
수정 중 붙여넣기에서 생긴 백틱·별표는 사용자가 붙여넣기 실수라고 정정했으므로 개념·작성 오류로 기록하지 않습니다.
### 틀린 이유·수정 사항
unit_price는 개당 가격입니다. 문제는 상품 항목 전체 금액이므로 quantity × unit_price를 비교해야 합니다. 수량 20개×단가 6파운드인 행은 120파운드로 고액에 포함됩니다. 고액 항목 수와 비율 분자에 같은 조건을 적용합니다.
### 최종 쿼리
```sql
SELECT country, COUNT(*) AS item_count,
    COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END) AS high_amount_count,
    ROUND(
        COUNT(CASE WHEN quantity * unit_price >= 100 THEN 1 END)
        / COUNT(*) * 100, 2
    ) AS high_amount_rate
FROM sales_items
GROUP BY country
HAVING item_count >= 100
ORDER BY high_amount_rate DESC, country ASC;
```
### 검증 — 사용자 실제 출력 전체

| country | item_count | high_amount_count | high_amount_rate |
| --- | --- | --- | --- |
| Netherlands | 2359 | 1132 | 47.99 |
| Japan | 321 | 126 | 39.25 |
| Australia | 1182 | 446 | 37.73 |
| Sweden | 451 | 136 | 30.16 |
| Denmark | 380 | 43 | 11.32 |
| Greece | 145 | 14 | 9.66 |
| Singapore | 222 | 16 | 7.21 |
| Finland | 685 | 43 | 6.28 |
| EIRE | 7890 | 469 | 5.94 |
| Hong Kong | 284 | 14 | 4.93 |
| Switzerland | 1966 | 95 | 4.83 |
| Israel | 295 | 14 | 4.75 |
| Norway | 1071 | 43 | 4.01 |
| Austria | 398 | 13 | 3.27 |
| Channel Islands | 748 | 22 | 2.94 |
| Spain | 2484 | 73 | 2.94 |
| Germany | 9040 | 246 | 2.72 |
| Cyprus | 614 | 14 | 2.28 |
| United Kingdom | 485123 | 10387 | 2.14 |
| France | 8407 | 165 | 1.96 |
| Malta | 112 | 2 | 1.79 |
| Iceland | 182 | 3 | 1.65 |
| Portugal | 1501 | 23 | 1.53 |
| Canada | 151 | 2 | 1.32 |
| Italy | 758 | 8 | 1.06 |
| Belgium | 2031 | 16 | 0.79 |
| Poland | 330 | 2 | 0.61 |
| USA | 179 | 0 | 0.00 |
| Unspecified | 446 | 0 | 0.00 |

2026-10-16 사용자 실행: 29 rows in set (5.35 sec).
Netherlands는 1132/2359×100 = 47.99%. USA와 Unspecified의 0건·0% 포함도 실제 확인했습니다.
**해결 방식:** 구조 직접 작성 → 항목 금액 조건·입력 오류 수정 피드백 → AI 정리 코드 제공 → 사용자 실행.
### 내 말로 정리
고액의 기준은 개당 가격이 아니라 한 상품 항목의 수량×단가다.
---
## P3 / 5 — 고객별 판매 수량과 구매금액
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 원본 중복 행은 제거하지 않았습니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| source_row_id | INT | 원본 상품 항목 행의 고유 번호 |
| invoice_header_id | INT | JOIN용 주문 정보 조합 ID |
| invoice_no | VARCHAR(20) | 원본 주문번호, 여러 상품 행에서 반복 가능 |
| quantity | INT | 해당 항목의 판매 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

위는 필요한 주요 컬럼 일부입니다. 상품 항목 금액은 quantity × unit_price입니다. 수량 6개·단가 2.55이면 한 행의 금액은 15.30파운드이며, 행 수는 1입니다.
**invoice_headers — 한 행은 주문번호·일시·고객·국가가 같은 정보 조합 하나입니다.** 원본에서 만든 학습용 표이며 공식 주문 마스터가 아닙니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| invoice_header_id | INT | 정보 조합의 고유 ID, 기본키 |
| invoice_no | VARCHAR(20) | 원본 주문번호 |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

두 표의 invoice_header_id가 같으면 해당 상품 항목과 주문 정보가 연결됩니다. 주문 정보 한 행에 상품 항목 여러 행이 붙을 수 있습니다.
### 문제
두 표를 연결하여 판매 수량 합계가 100개 이상인 고객의 ID, 상품 항목 수, 수량 합계와 구매금액 합계를 조회하세요. 결과 한 행은 고객 한 명의 통계입니다.
### 조건
- 고객 ID가 NULL인 기록은 제외하고 전체 기간을 사용합니다.
- 같은 고객의 상품 항목을 모두 합하며 수량 합계가 정확히 100개인 고객도 포함합니다.
- 항목 수는 행 수이며 주문 수나 판매 수량과 다릅니다.
- 금액은 quantity × unit_price 합계이며 최종 소수점 둘째 자리 반올림합니다.
- 반올림 금액 내림차순, 같으면 고객 ID 오름차순입니다.
- 두 표를 연결하고 고객 ID는 invoice_headers, 수량·단가는 sales_items에서 가져옵니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_id | 고객 ID |
| item_count | 상품 항목 행 수 |
| total_quantity | 수량 합계 |
| total_purchase_amount | 구매금액 합계(GBP) |

### 출력 예시 — 가상

| customer_id | item_count | total_quantity | total_purchase_amount |
| --- | --- | --- | --- |
| 10001 | 20 | 150 | 1250.00 |
| 10002 | 10 | 100 | 800.00 |

### 예시 설명
10001번은 20행에 수량 150개입니다. 10002번은 수량이 정확히 100개라 포함합니다. 100행 이상이라는 조건이 아닙니다.
예시는 이해를 위한 가상 결과입니다. 실제 사용자 실행 결과는 아래 검증 항목에 따로 기록합니다.
### 내 첫 시도
```sql
SELECT h.customer_id, COUNT(*) AS item_count,
    COUNT(quantity) AS total_quantity,
    ROUND(SUM(s.quantity * s.unit_price), 2) AS total_purchase_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
GROUP BY h.customer_id
HAVING total_quantity >= 100
ORDER BY total_purchase_amount DESC, h.customer_id ASC;
```
### 실행 결과·오류
실행은 됐지만 COUNT(quantity)가 행 수를 세어 item_count와 total_quantity가 같았습니다. NULL 고객 그룹도 132220행·1755276.64파운드로 첫 행에 포함됐습니다. 이 그룹은 고객 한 명이 아니라 ID를 알 수 없는 기록의 묶음입니다.
### 틀린 이유·수정 사항
COUNT(quantity)는 NULL이 아닌 수량 값의 개수이며 수량 합계가 아닙니다. SUM(s.quantity)로 수정하고, GROUP BY 전에 h.customer_id IS NOT NULL 조건을 추가했습니다.
JOIN 키·금액 합계·고객별 집계·정렬 방향은 직접 맞췄습니다.
### 최종 쿼리
```sql
SELECT h.customer_id, COUNT(*) AS item_count,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.quantity * s.unit_price), 2) AS total_purchase_amount
FROM invoice_headers h
JOIN sales_items s ON s.invoice_header_id = h.invoice_header_id
WHERE h.customer_id IS NOT NULL
GROUP BY h.customer_id
HAVING total_quantity >= 100
ORDER BY total_purchase_amount DESC, h.customer_id ASC;
```
### 검증 — 사용자가 제공한 실제 출력 일부

| customer_id | item_count | total_quantity | total_purchase_amount |
| --- | --- | --- | --- |
| 14646 | 2076 | 196915 | 280206.02 |
| 18102 | 431 | 64124 | 259657.30 |
| 17450 | 337 | 69993 | 194550.79 |
| 16446 | 3 | 80997 | 168472.50 |
| 14911 | 5675 | 80265 | 143825.06 |
| 12415 | 714 | 77374 | 124914.53 |
| 14156 | 1400 | 57885 | 117379.63 |
| 17511 | 963 | 64549 | 91062.38 |
| 16029 | 242 | 40208 | 81024.84 |
| 12346 | 1 | 74215 | 77183.60 |
| 16684 | 277 | 50255 | 66653.56 |
| 14096 | 5111 | 16352 | 65164.79 |
| 13694 | 568 | 63312 | 65039.62 |
| 15311 | 2379 | 38194 | 60767.90 |
| 13089 | 1818 | 31070 | 58825.83 |
| 17949 | 70 | 30546 | 58510.48 |
| 15769 | 130 | 29672 | 56252.72 |
| 15061 | 403 | 28920 | 54534.14 |
| 14298 | 1637 | 58343 | 51527.30 |
| 14088 | 589 | 12665 | 50491.81 |
| 15749 | 10 | 18028 | 44534.30 |

2026-10-16 실행 결과에서 공유된 21행을 기록했습니다. 전체 출력 행 수와 실행 시간은 제출되지 않아 확정하지 않습니다.
16446번은 항목이 3행이지만 수량 합계는 80997개여서 포함됩니다. COUNT 기준으로 선별했다면 제외됐을 사례입니다.
**해결 방식:** JOIN·금액 계산 직접 작성 → COUNT와 SUM·NULL 제외 힌트 → 직접 수정·사용자 실행.
### 내 말로 정리
NULL 고객은 실제 한 사람이 아니다. 고객을 식별하는 분석에서는 제외 기준을 명시한다.


### 🧩 문제 4 — 누적 구매금액 조건을 만족하는 고객 수
## P4 / 5 — 누적 구매금액이 1,000파운드 이상인 고객 수
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 원본 중복 행은 제거하지 않았습니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| source_row_id | INT | 원본 상품 항목 행의 고유 번호 |
| invoice_header_id | INT | JOIN용 주문 정보 조합 ID |
| invoice_no | VARCHAR(20) | 원본 주문번호, 여러 상품 행에서 반복 가능 |
| quantity | INT | 해당 항목의 판매 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

위는 필요한 주요 컬럼 일부입니다. 상품 항목 금액은 quantity × unit_price입니다. 수량 6개·단가 2.55이면 한 행의 금액은 15.30파운드이며, 행 수는 1입니다.
### 문제
고객별 누적 구매금액이 1,000파운드 이상인 고객이 몇 명인지 조회하세요. 최종 결과는 조건을 만족한 고객 수 한 행입니다.
### 조건
- 고객 ID가 NULL인 기록은 제외하고 전체 기간을 사용합니다.
- 고객의 모든 상품 항목 금액 quantity × unit_price를 합산합니다.
- 상품 항목 하나의 금액이 아니라 고객별 누적 금액으로 판단합니다. 정확히 1,000파운드도 포함합니다.
- 금액은 중간에 반올림하지 않습니다.
- 조건을 만족하는 고객이 없으면 0. 정렬 없음, sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer_count | 조건을 만족한 고객 수 |

### 출력 예시 — 가상

| customer_count |
| --- |
| 2 |

### 예시 설명
가상 고객 A의 항목 금액이 600+500이면 누적 1100으로 포함합니다. B는 1000으로 포함, C는 999로 제외하므로 2명입니다.
예시는 이해를 위한 가상 결과입니다. 실제 사용자 실행 결과는 아래 검증 항목에 따로 기록합니다.
### 내 첫 시도·최종 쿼리
```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT SUM(quantity * unit_price) AS price
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING price >= 1000
) AS count;
```
### 실행 결과·오류
2026-10-16 첫 제출 정답. 수정 없음.
### 검증 — 사용자 실제 출력

| customer_count |
| --- |
| 1668 |

조건을 만족한 고객은 1668명입니다. 실행 시간은 제출되지 않았습니다.
**해결 방식:** 안쪽 SUM·NULL 제외·GROUP BY·HAVING 및 바깥 COUNT를 직접 작성 → 첫 제출 정답 → 사용자 실행.
### 내 말로 정리·한 행의 의미
안쪽 SELECT에 customer_id를 출력하지 않아도 GROUP BY customer_id가 있으므로 한 행은 고객 한 명입니다. 바깥 COUNT는 그 중간 결과의 행을 셉니다.
안쪽에서 누적 금액 기준으로 고객을 선별하고, 바깥에서 남은 고객 수를 센다.


### 🧩 문제 5 — 고객별 누적 구매금액의 평균
## P5 / 5 — 고객별 누적 구매금액의 평균
### 테이블 설명
**sales_items — 한 행은 주문에 포함된 상품 항목 하나입니다.** 수량·단가가 양수이고 주문번호가 C로 시작하지 않는 원본 기록을 보여 주는 뷰입니다. 원본 중복 행은 제거하지 않았습니다.

| 컬럼 | 자료형 | 설명 |
| --- | --- | --- |
| source_row_id | INT | 원본 상품 항목 행의 고유 번호 |
| invoice_header_id | INT | JOIN용 주문 정보 조합 ID |
| invoice_no | VARCHAR(20) | 원본 주문번호, 여러 상품 행에서 반복 가능 |
| quantity | INT | 해당 항목의 판매 수량 |
| unit_price | DECIMAL(16,6) | 개당 가격, GBP |
| customer_id | VARCHAR(20) | 고객 ID, NULL 허용 |
| country | VARCHAR(100) | 국가 이름 |

위는 필요한 주요 컬럼 일부입니다. 상품 항목 금액은 quantity × unit_price입니다. 수량 6개·단가 2.55이면 한 행의 금액은 15.30파운드이며, 행 수는 1입니다.
### 문제
누적 구매금액이 1,000파운드 이상인 고객 각각의 누적 구매금액을 구하고, 그 고객별 누적 구매금액들의 평균을 조회하세요. 상품 항목 수나 구매 수량이 달라도 고객 한 명당 같은 비중으로 반영합니다.
### 조건
- 고객 ID NULL을 제외하고 전체 기간을 사용합니다.
- 고객별 누적 금액은 모든 상품 항목의 quantity × unit_price 합계입니다.
- 정확히 1,000파운드인 고객도 포함합니다.
- 고객별 금액은 중간 반올림하지 않고 최종 평균만 소수점 둘째 자리까지 반올림합니다.
- 최종 결과 한 행, 정렬 없음, sales_items만 사용합니다.
### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| avg_customer_total | 대상 고객들의 누적 구매금액 평균(GBP) |

### 출력 예시 — 가상

| avg_customer_total |
| --- |
| 1500.00 |

### 예시 설명
가상 고객 A=1200, B=1800, C=900이면 C는 제외합니다. (1200+1800)/2=1500입니다. 최종 출력 한 행이 중간 집계도 한 행이라는 뜻은 아닙니다.
예시는 이해를 위한 가상 결과입니다. 실제 사용자 실행 결과는 아래 검증 항목에 따로 기록합니다.
### 내 첫 시도·최종 쿼리
```sql
SELECT ROUND(AVG(price), 2) AS avg_customer_total
FROM (
    SELECT SUM(quantity * unit_price) AS price
    FROM sales_items
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING price >= 1000
) AS count;
```
### 실행 결과·오류
2026-10-16 첫 제출 정답. 수정 없음. 문제 4에서 직접 만든 중간 집계 구조를 재사용해 바깥 AVG와 최종 ROUND를 적용했습니다.
### 검증 — 사용자 실제 출력

| avg_customer_total |
| --- |
| 4678.46 |

1 row in set (0.61 sec).
**해결 방식:** 직접 작성 → 첫 제출 정답 → 사용자 실행 확인. 이 문제의 제출 전 수정 코드·부분 틀 도움 없음.
### 내 말로 정리·한 행의 의미
P4·P5의 중간 결과는 고객별 누적 금액으로 같습니다. 바깥 COUNT는 1668명을 세고 바깥 AVG는 그 고객들의 누적 금액을 평균 내어 4678.46파운드를 반환합니다.
항목별 평균이 아니라 고객별 총액의 평균이며, 최종 단계에서만 반올림한다.


### 🔎 오늘 꼭 이해할 부분 — 행·수량·금액·NULL·중간 표
## 건수·수량·금액은 다르다

| 목적 | 계산 대상 |
| --- | --- |
| 상품 항목 수 | 행 수 |
| 판매 수량 | quantity 합계 |
| 상품 항목 금액 | quantity × unit_price |
| 고객 누적 구매금액 | 고객별 항목 금액 합계 |
| 고객 수 | 고객별 중간 결과의 행 수 |
| 고객당 누적 금액 평균 | 고객별 합계 값들의 평균 |

설명용 예: 수량 6·8인 두 행은 2행, 총수량 14개입니다. 단가가 6이고 수량이 20인 한 행은 120파운드이므로 고액입니다.
## NULL 고객 처리
국가별 분석 P1·P2는 고객 ID를 몰라도 포함합니다. 고객별 분석 P3\~P5는 customer_id IS NOT NULL로 제외합니다. 같은 NULL을 상황에 따라 달리 처리한 것이며, 분석 단위가 다르기 때문입니다.
## JOIN 후 한 행
sales_items의 한 행에 invoice_headers 정보 한 행이 붙는 구조입니다. 같은 주문번호의 서로 다른 정보 조합 때문에 invoice_no만 JOIN하면 행이 늘어날 수 있으므로 연결용 ID를 사용합니다.
## 서브쿼리 재집계
원본 상품 항목 여러 행 → 고객별 SUM·HAVING → 대상 고객 한 명당 한 행 → 바깥 COUNT 또는 AVG.
P4·P5에서는 사용자가 이 전체 구조를 수정 도움 없이 직접 작성했습니다. 실행 성공뿐 아니라 첫 제출 내용으로 확인한 진전입니다. 다른 구조의 서브쿼리까지 모두 독립 해결한다고 확대 해석하지 않습니다.
## 표 별칭과 컬럼 별칭
제출본의 price는 중간 표의 컬럼, count는 중간 표의 별칭입니다. 바깥 AVG(price)는 컬럼의 평균을 구합니다. 표 이름 자체를 COUNT 대상으로 넣는 것과 다릅니다.


### 🧠 학습 회고·검증 범위·재풀이
## 문제별 상태

| 문제 | 실행 날짜 | 결과 | 도움 범위 |
| --- | --- | --- | --- |
| P1 | 2026-10-15 | 정답·28행 | 첫 제출 수정 없음 |
| P2 | 2026-10-16 | 정답·29행 | 단가→항목 금액 조건, 입력 오류 수정·정리 코드 |
| P3 | 2026-10-16 | 정답·제공 출력 일부 확인 | COUNT→SUM·NULL 고객 제외 힌트 |
| P4 | 2026-10-16 | 첫 제출 정답·1668명 | 제출 전 풀이 수정 도움 없음 |
| P5 | 2026-10-16 | 첫 제출 정답·4678.46파운드 | 제출 전 풀이 수정 도움 없음 |

5문제 모두 사용자 실행을 확인했습니다. P3는 전체 행 수를 확정하지 않습니다.
## 관찰된 진전
F1에서 연습한 안쪽 그룹 집계·조건 선별과 바깥 집계를 새 소매 데이터에 옮겼습니다. P4의 COUNT와 P5의 AVG를 두 문제 연속으로 수정 도움 없이 작성했습니다.
## 계속 확인할 부분
문장의 수량·건수 구분, 단가와 항목 금액 구분, NULL 포함·제외 기준, 같은 패턴을 조건이 달라져도 유지할 수 있는지.
## 재풀이 계획 — 미실행
- [ ] 누적 구매금액 기준을 바꾼 고객 수 문제를 답 없이 작성
- [ ] 동일 대상 고객들의 총액 평균을 답 없이 작성
- [ ] 안쪽 한 행이 무엇인지 설명
- [ ] 바깥 COUNT·AVG가 읽는 대상을 설명
구조를 무조건 외우기보다 중간 표의 한 행이 고객 한 명이라는 기준으로 COUNT와 AVG를 선택했다. 사용자 직접 회고로 확인된 문장은 아닙니다.

