# Day 13 — 2026-10-11

[English](../en/day13.md) · [목차](../../README.ko.md)

노션의 상세 기록을 공개용으로 정리했습니다. SQL·실행 결과는 당시 기록이며 게시를 위해 재실행하지 않았습니다. 거래 연습 데이터의 식별자는 가명 처리했습니다.

# SQL 학습 기록 — Day 13
## Finance SQL Day (2026-10-11)
**학습일:** 2026-10-11
**환경:** MySQL / finance / bank_transactions
**범위:** 조건부 집계·비율·서브쿼리 2단계 집계, P1\~P5.
**번호 근거:** 현재 SQL TIL의 최상위 Day1\~Day11 뒤에 2026-10-10 학습 기록이 이어진다. 이를 Day12로, 오늘 기록을 Day13으로 부여했다. 기록된 SQL 학습 세션 순서이며 달력상 연속 일수나 Salesforce 수업 DAY 번호가 아니다.
**검증 근거:** 사용자 직접 실행 결과. 이번 업로드에서 AI가 DB를 재실행하지 않았다. 첫 시도의 논리는 보존하고 SQL 줄바꿈·마지막 세미콜론은 가독성을 위해 정리했다.
### 접속
일반 터미널:
```bash
mysql --local-infile=1 -u root -p
```
MySQL:
```sql
USE finance;
DESCRIBE bank_transactions;
```

| 컬럼 | 타입 | NULL 허용 | 의미 |
| --- | --- | --- | --- |
| customer_id | VARCHAR(20) | 아니요 | 고객 ID |
| transaction_amount | DECIMAL(15,2) | 아니요 | 거래 금액 |

원본 한 행 = 거래 1건.

### 📚 문제 1\~3 — 조건부 건수·금액·비율
## P1 / 5 — 고액 거래를 여러 번 한 고객
### 문제
금액이 5,000 이상인 거래를 2건 이상 한 고객을 조회한다. 고객 ID, 고액 거래 건수(high_amount_count), 고액 거래 금액 합계(high_amount_total)를 출력한다. 합계 내림차순, 고객 ID 오름차순으로 정렬한다.
결과 한 행 = 조건을 만족한 고객 한 명. JOIN 없음. GROUP BY 기준 = customer_id.
### 내 첫 시도
```sql
SELECT customer_id,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    SUM(CASE WHEN transaction_amount >= 5000 THEN 1 ELSE 0 END) AS high_amount_total
FROM bank_transactions
GROUP BY customer_id
ORDER BY high_amount_total DESC, customer_id ASC;
```
### 실행 결과·오류
문법 오류 없이 실행됐지만 금액 합계 컬럼에도 3, 2, 0 같은 건수가 출력됐고 고액 거래가 2건 미만인 고객도 포함됐다.
금액 합계를 먼저 수정한 두 번째 실행에서도 HAVING이 없어 고액 거래 1건인 고객이 출력됐다.
### 틀린 이유
SUM의 CASE에서 THEN 1을 사용해 건수를 더했다. 금액 합계에는 실제 금액을 반환해야 한다. 고액 거래 2건 이상이라는 집계 조건도 누락했다.
### 수정 쿼리
```sql
SELECT customer_id,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    SUM(CASE WHEN transaction_amount >= 5000 THEN transaction_amount ELSE 0 END) AS high_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING high_amount_count >= 2
ORDER BY high_amount_total DESC, customer_id ASC;
```
### 검증
사용자가 제공한 실제 결과 일부:

| customer_id | high_amount_count | high_amount_total |
| --- | --- | --- |
| FIN_CUSTOMER_021 | 2 | 317471.25 |
| FIN_CUSTOMER_017 | 2 | 309093.00 |
| FIN_CUSTOMER_026 | 2 | 205029.12 |
| FIN_CUSTOMER_010 | 2 | 200000.00 |
| FIN_CUSTOMER_019 | 2 | 200000.00 |

SQL 논리가 요구사항에 부합한다. 제공된 결과에서 건수 조건과 정렬을 확인했다. 전체 출력 건수와 원본 거래별 금액 대조는 미확인.
**해결 방식:** 직접 작성 → AI 힌트·부분 수정 코드 후 합계 수정 → AI가 제시한 HAVING 조건 추가 → 실행.
### 내 말로 정리
사용자 표현: “1이 아니라 거래 금액을 출력해서 더해라?”
정확히는 화면 출력이 아니라 SUM이 더할 값으로 거래 금액을 반환한다.
---
## P2 / 5 — 전체 거래와 소액 거래 함께 조회
### 문제
전체 거래가 5건 이상인 고객의 전체 거래 건수(total_transaction_count), 1,000 미만 소액 거래 건수(small_amount_count), 소액 거래 금액 합계(small_amount_total)를 조회한다. 소액 거래가 없는 고객도 포함하고 건수·합계는 0으로 표시한다. 소액 거래 건수 내림차순, 고객 ID 오름차순.
결과 한 행 = 고객 한 명. 전체 거래를 유지하면서 일부 거래만 따로 집계한다.
### 내 첫 시도
```sql
SELECT customer_id,
    COUNT(CASE WHEN transaction_amount THEN 1 END) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    SUM(CASE WHEN transaction_amount THEN transaction_amount ELSE 0 END) AS small_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_count DESC, customer_id ASC;
```
### 실행 결과·오류
정상 실행됐지만 전체 COUNT에 불필요한 조건이 있었고 소액 SUM에는 1,000 미만 조건이 없었다. C6222360은 소액 거래 5건인데 합계가 5825.00으로 출력됐다.
### 틀린 이유
MySQL에서 WHEN transaction_amount는 0이 아닌 금액을 참으로 취급한다. 전체 거래 건수에는 조건 없이 COUNT(\*)를 사용한다. SUM에도 소액 조건이 필요하다. 1,000 미만인 거래 5건의 합계는 5,000 미만이어야 한다.
### 수정 쿼리
```sql
SELECT customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    SUM(CASE WHEN transaction_amount < 1000 THEN transaction_amount ELSE 0 END) AS small_amount_total
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_count DESC, customer_id ASC;
```
### 검증
사용자가 제공한 실제 결과 일부:

| customer_id | total_transaction_count | small_amount_count | small_amount_total |
| --- | --- | --- | --- |
| FIN_CUSTOMER_005 | 6 | 5 | 2091.00 |
| FIN_CUSTOMER_008 | 5 | 5 | 1826.00 |
| FIN_CUSTOMER_009 | 5 | 5 | 1322.00 |
| FIN_CUSTOMER_023 | 6 | 5 | 525.00 |

C6222360의 합계가 5825.00에서 525.00으로 변경됐다. SQL 구조상 소액 거래가 없는 고객도 포함되고 건수·합계는 0이다. 실제 0건 고객 행과 전체 출력 건수는 제공 범위에서 미확인.
**해결 방식:** 직접 작성 → AI 설명 후 전체 COUNT와 소액 SUM 수정 → 실행.
### 핵심 개념 정리
전체 거래를 세는 COUNT에는 조건을 넣지 않는다. 일부 거래의 건수나 금액을 구할 때 CASE WHEN으로 조건을 지정한다.
---
## P3 / 5 — 고객별 소액 거래 비율
### 문제
전체 거래가 5건 이상인 고객의 전체 거래 건수, 1,000 미만 소액 거래 건수, 소액 거래 비율(small_amount_rate)을 조회한다. 소액 거래가 없는 고객도 포함하고 비율은 0으로 표시한다. 소수점 둘째 자리까지 반올림한 비율 내림차순, 고객 ID 오름차순.
비율(%) = 소액 거래 건수 ÷ 전체 거래 건수 × 100.
### 내 첫 시도 — 수정 없이 정답
```sql
SELECT customer_id,
    COUNT(*) AS total_transaction_count,
    COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) AS small_amount_count,
    ROUND(
        COUNT(CASE WHEN transaction_amount < 1000 THEN 1 END) / COUNT(*) * 100,
        2
    ) AS small_amount_rate
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_count >= 5
ORDER BY small_amount_rate DESC, customer_id ASC;
```
### 실행 결과·오류
정상 실행. 첫 제출 쿼리에 대한 추가 수정 없음.
### 틀린 이유·수정 쿼리
해당 없음. 위 첫 시도가 최종 쿼리다.
### 검증
사용자가 제공한 실제 결과 일부:

| customer_id | total_transaction_count | small_amount_count | small_amount_rate |
| --- | --- | --- | --- |
| FIN_CUSTOMER_008 | 5 | 5 | 100.00 |
| FIN_CUSTOMER_009 | 5 | 5 | 100.00 |
| FIN_CUSTOMER_011 | 5 | 5 | 100.00 |
| FIN_CUSTOMER_013 | 5 | 5 | 100.00 |

5 ÷ 5 × 100 = 100%. 분자·분모, 반올림, 필터, 정렬이 정확하다. 제공된 결과는 100% 고객 일부이므로 다른 비율·0% 고객·전체 출력 건수는 미확인.
**해결 방식:** 앞선 P2 학습을 바탕으로 작성 → 첫 제출 수정 없이 실행 결과 확인. 이전 코드를 참고했는지 여부는 별도 확인하지 않았다.
### 핵심 개념 정리
비율의 분모는 전체 거래 건수다. 소액 거래만 먼저 남기면 전체 거래를 기준으로 한 비율을 구할 수 없다.


### 🧩 문제 4\~5 — 서브쿼리로 고객 단위 재집계
## P4 / 5 — 고객별 총 거래 금액의 평균
### 문제
모든 고객의 전체 기간 총 거래 금액을 구한 뒤, 그 고객별 총액들의 평균을 소수점 둘째 자리까지 반올림한다. 출력 컬럼 avg_customer_total, 결과 한 행, 정렬 조건 없음.
### 내 첫 시도 — 중간 표
```sql
SELECT customer_id, COUNT(*) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id;
```
### 실행 결과·오류
C1010011은 2, C1010012는 1, C1010014는 2로 출력됐다. 이는 금액이 아닌 고객별 거래 건수다.
### 틀린 이유
AS는 컬럼 이름만 바꾼다. 별칭을 금액으로 지정해도 COUNT(\*)는 행 수를 센다.
### 수정한 중간 쿼리
```sql
SELECT customer_id, SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id;
```
실제 결과 일부:

| customer_id | total_transaction_amount |
| --- | --- |
| FIN_CUSTOMER_001 | 5106.00 |
| FIN_CUSTOMER_002 | 1499.00 |
| FIN_CUSTOMER_003 | 1455.00 |
| FIN_CUSTOMER_004 | 30.00 |

중간 결과 한 행 = 고객 한 명의 총 거래 금액.
### 최종 쿼리
AI가 제공한 바깥 틀의 AVG 빈칸에 사용자가 total_transaction_amount를 입력했다.
```sql
SELECT ROUND(AVG(total_transaction_amount), 2) AS avg_customer_total
FROM (
    SELECT customer_id,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
) AS customer_totals;
```
### 검증

| avg_customer_total |
| --- |
| 1866.86 |

실제 실행 메시지: 1 row in set (4.42 sec).
고객별 총액을 다시 평균 내는 논리가 맞고 사용자 실행 결과를 확인했다. 원본 합계 ÷ 고유 고객 수 방식의 별도 대조는 이번 문제에서 수행하지 않았다.
**해결 방식:** 중간 쿼리 직접 작성 → AI 힌트로 COUNT를 SUM으로 수정 → AI 제공 바깥 틀의 빈칸 작성 → 실행.
### 핵심 개념 정리
거래 한 건의 평균과 고객 한 명당 총 거래 금액의 평균은 다르다. 고객별 총액을 먼저 만들어야 고객 단위 평균을 계산할 수 있다.
---
## P5 / 5 — 누적 거래 금액이 10,000 이상인 고객 수
### 문제
전체 기간의 누적 거래 금액이 10,000 이상인 고객 수를 조회한다. 고객의 모든 거래를 합산해서 판단하며, 거래 한 건의 금액 조건이 아니다. 출력 컬럼 customer_count, 결과 한 행, 정렬 조건 없음.
### 내 첫 시도 — 중간 표
```sql
SELECT customer_id, SUM(transaction_amount) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING total_transaction_amount >= 10000;
```
고객별 SUM과 HAVING을 직접 올바르게 작성했다. 표시용 줄바꿈과 문장 끝 세미콜론을 정리했다.
### 실행 결과·오류
첫 중간 쿼리의 별도 실행 결과는 제출되지 않았다. 이후 최종 서브쿼리 실행 결과는 제출됐다. 집계 논리 오류 없음.
### 틀린 이유·수정 사항
집계 논리 수정 없음. AI가 제공한 바깥 쿼리 틀의 빈칸에 사용자가 COUNT(\*)를 입력했다.
### 최종 쿼리
```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT customer_id,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING total_transaction_amount >= 10000
) AS qualifying_customers;
```
### 검증

| customer_count |
| --- |
| 26455 |

사용자가 제공한 실행 결과에서 조건에 맞는 고객 수는 26,455명이다. 별도 방식의 대조 검증은 수행하지 않았다.
**해결 방식:** 안쪽 집계·HAVING 직접 작성 → AI 제공 바깥 틀에 COUNT(\*) 선택 → 실행. 전체 서브쿼리 독립 작성으로 평가하지 않는다.
### 내 말로 정리·이해 확인
사용자 질문: “AS 정한 것도 없고 GROUP BY 정한 것도 없고”
출력 컬럼의 AS는 이름을 붙이는 선택 사항이다. GROUP BY 없이 전체를 하나로 집계할 수도 있다. MySQL의 FROM (서브쿼리)에는 표 별칭이 필요하지만 AS 키워드 자체는 생략할 수 있다.
가상 예시에서 A 거래 3건, B 거래 2건을 고객별 합산하면 몇 행인지 물었을 때 사용자 답변: “2건만 출력??? a,b 고객으로 묶어서”
**확인된 이해:** A·B로 묶으면 중간 표가 2행이라는 점을 설명했다. 정확한 단위는 거래 2건이 아니라 고객 2명에 해당하는 2행이다.
**미확인:** 전체 서브쿼리 빈 화면 재작성.


### 🔎 오늘 꼭 이해할 부분 — SUM·CASE·COUNT와 한 행의 의미
## THEN에서 어떤 값을 반환하는가?
사용자 질문: “SUM CASE WHEN 이 부분 THEN 다음에 왜 transaction_amount 넣는거야”, “ELSE는 왜 0이지”, “0도 결과표에 출력 되는건가”
CASE는 각 거래에서 사용할 값을 정하고 SUM은 반환된 숫자를 더한다. 다음은 설명용 가상 예시다.

| 원본 금액 | THEN 1 ELSE 0 | THEN transaction_amount ELSE 0 |
| --- | --- | --- |
| 200 | 1 | 200 |
| 600 | 1 | 600 |
| 3000 | 0 | 0 |
| SUM 결과 | 2건 | 800 |

### ELSE 0과 NULL
조건에 맞지 않는 거래는 0을 반환하여 합계에 영향을 주지 않게 한다. ELSE를 생략하면 불일치 행은 NULL이다. SUM은 NULL을 제외하지만 전부 NULL이면 결과도 NULL이다.

| 고객의 거래 — 가상 예시 | ELSE 0 사용 | ELSE 생략 |
| --- | --- | --- |
| 200, 600, 3000 | 800 | 800 |
| 2000, 3000 | 0 | NULL |

거래마다 반환된 0이 별도 행으로 출력되는 것이 아니다. 고객별 최종 합계가 출력되며, 소액 거래가 없으면 최종 합계가 0이다.
COUNT는 NULL이 아닌 값을 세므로 0도 센다. 따라서 조건부 COUNT에는 ELSE 0을 넣지 않는다.
## COUNT(\*)가 세는 대상
사용자 직접 실행:
```sql
SELECT COUNT(*)
FROM bank_transactions;
```

| COUNT(\*) |
| --- |
| 1048567 |

실제 실행 메시지: 1 row in set (0.53 sec).
1,048,567은 고객 수가 아니라 전체 거래 건수다.

| 목적 | 방법 |
| --- | --- |
| 전체 거래 수 | 원본에서 COUNT(\*) |
| 전체 고유 고객 수 | 원본에서 COUNT(DISTINCT customer_id) |
| 누적 금액 조건에 맞는 고객 수 | 고객별 합산·필터링 후 바깥 COUNT(\*) |

COUNT(DISTINCT customer_id)는 오늘 설명에 사용했으며 별도 실행 결과는 제출되지 않았다.
## 서브쿼리의 한 행 의미
원본 한 행 = 거래 1건 → 고객별 GROUP BY와 SUM → 중간 한 행 = 고객 한 명의 총액 → AVG는 총액 평균, COUNT(\*)는 고객 행 수.
이는 계산을 이해하기 위한 논리적 순서이며 DB의 물리적 실행 순서를 단정하지 않는다.
단순 고유 고객 수만 필요하면 GROUP BY 없이 COUNT(DISTINCT customer_id)로 구할 수 있다. P5는 고객별 누적 금액 조건이 있으므로 먼저 고객별 합계가 필요하다.


### 🧠 오늘의 회고·검증 범위·재풀이
## 해결 상태

| 문제 | 확인된 결과 | 도움받은 범위 |
| --- | --- | --- |
| P1 | 제공 출력 범위 검증 | 금액 합계·HAVING 수정 도움 |
| P2 | 제공 출력 범위 검증 | 전체 COUNT·소액 SUM 조건 수정 도움 |
| P3 | 첫 제출 정답·제공 출력 범위 검증 | 앞선 학습 활용, 제출 후 수정 없음 |
| P4 | 사용자 실행 1866.86 확인 | SUM 수정 도움·바깥 틀 제공 |
| P5 | 사용자 실행 26455 확인 | 안쪽 직접 작성·바깥 틀 제공 |

실행 성공과 독립 작성 능력은 구분한다.
## 오늘 혼자 할 수 있었던 것
관찰된 코드·답변 기준: 고객별 GROUP BY, 조건부 거래 건수, P3의 비율·반올림, P5의 안쪽 SUM·HAVING, 바깥 틀에서 COUNT(\*) 선택, A·B를 묶으면 중간 표가 2행이라는 설명.
## 아직 도움이 필요한 것
건수·금액에 맞는 함수 선택, CASE 반환값과 집계함수의 관계, ELSE 0·NULL 처리, 중간 표 설계, 전체 서브쿼리 독립 작성, GROUP BY 필요 여부 판단.
## 답을 보지 않고 다시 풀 문제 1개
P5 — 누적 거래 금액이 10,000 이상인 고객 수.
- [ ] 고객별 총 거래 금액을 직접 구하기
- [ ] 합계 조건으로 고객 필터링
- [ ] 중간 결과 한 행의 의미 설명
- [ ] 바깥 쿼리로 고객 수 계산
**재풀이 상태: 미실행.** 이후 결과를 확인하기 전까지 독립 해결로 기록하지 않는다.



