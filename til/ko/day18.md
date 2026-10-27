# Day 18 — Finance 월별 집계·거래일 수·서브쿼리

[English](../en/day18.md) · [목차](../../README.ko.md)

<details>
<summary>💳 Day18 — Finance 월별 집계·거래일 수·서브쿼리</summary>

# SQL 학습 기록 — Day 18

## 학습 개요

**환경:** MySQL / finance / bank\_transactions
**학습 범위:** 월별 거래 통계, 조건부 집계, 서로 다른 거래 날짜 수, 고객별 누적 금액 재집계.
**검증 근거:** 사용자가 직접 공유한 MySQL 결과. 업로드 전 AI가 읽기 전용 재집계로 월별 통계와 문제 4·5의 고객 수·평균을 대조하여 일치를 확인했습니다.


### 접속

일반 터미널:

```bash
mysql -u root -p
```

mysql> 화면:

```sql
USE finance;
SHOW TABLES;
```

이미 접속했다면 USE부터 실행합니다.

### 데이터와 한 행의 의미

**bank\_transactions — 한 행은 금융 거래 한 건입니다.** 같은 고객이 같은 날짜에 여러 번 거래할 수 있습니다. 아래는 이번 문제에 필요한 컬럼 일부입니다.

| 컬럼명 | 자료형 | 의미 |
| --- | --- | --- |
| transaction\_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer\_id | VARCHAR(20) | 고객 ID |
| transaction\_date | DATE | 거래 날짜, 시각 없음 |
| transaction\_amount | DECIMAL(15,2) | 거래금액 |

위 컬럼에는 NULL이 없습니다. 데이터의 날짜 범위는 2016-08-01부터 2016-10-21까지입니다. 금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.
현재 전체 거래는 1048567행이며 거래 ID는 중복되지 않습니다. 월별 통계는 거래 한 건을, 문제 4·5의 바깥 집계는 고객별 중간 결과를 대상으로 합니다.

<details>
<summary>📚 문제 1\~3 — 월별 거래·고액 비율·고객별 거래일 수</summary>

## 문제 1. 월별 거래 통계

### 테이블 설명

**bank\_transactions — 한 행은 금융 거래 한 건입니다.** 같은 고객이 같은 날짜에 여러 번 거래할 수 있습니다. 아래는 이번 문제에 필요한 컬럼 일부입니다.

| 컬럼명 | 자료형 | 의미 |
| --- | --- | --- |
| transaction\_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer\_id | VARCHAR(20) | 고객 ID |
| transaction\_date | DATE | 거래 날짜, 시각 없음 |
| transaction\_amount | DECIMAL(15,2) | 거래금액 |

위 컬럼에는 NULL이 없습니다. 데이터의 날짜 범위는 2016-08-01부터 2016-10-21까지입니다. 금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

전체 기간의 연월별 거래 건수, 총 거래금액, 거래 한 건당 평균 금액을 조회합니다. 결과 한 행은 특정 연도의 한 달에 대한 거래 통계입니다.

### 조건

- 거래 연월은 YYYY-MM 형식으로 출력합니다.
- 전체 거래 행 수, 금액 합계와 평균을 계산합니다.
- 총액과 평균은 소수점 둘째 자리까지 표시합니다.
- 기록이 있는 연월만 출력하고 거래 연월 오름차순으로 정렬합니다.
- 최소 건수·금액 조건이 없으며 bank\_transactions만 사용합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| transaction\_month | 거래 연월, YYYY-MM |
| transaction\_count | 거래 건수 |
| total\_transaction\_amount | 총 거래금액 |
| avg\_transaction\_amount | 거래 한 건당 평균 금액 |

### 출력 예시 — 가상

| transaction\_month | transaction\_count | total\_transaction\_amount | avg\_transaction\_amount |
| --- | --- | --- | --- |
| 2016-08 | 200 | 100000.00 | 500.00 |
| 2016-09 | 100 | 75000.00 | 750.00 |

### 예시 설명

가상의 8월 거래 200건 합계가 100000이면 한 건당 평균은 500입니다. 고객당 평균이 아닙니다.

### 제출 쿼리

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS avg_transaction_amount
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;
```

### 검증

| transaction\_month | transaction\_count | total\_transaction\_amount | avg\_transaction\_amount |
| --- | --- | --- | --- |
| 2016-08 | 653933 | 1030599493.84 | 1576.00 |
| 2016-09 | 390975 | 612531219.10 | 1566.68 |
| 2016-10 | 3659 | 7665018.63 | 2094.84 |

실행 결과: 3 rows in set (1.21 sec).

### 핵심 개념 정리

날짜를 연월로 바꾼 값을 그룹화 기준으로 사용했습니다. transaction\_amount는 소수점 두 자리의 정확한 DECIMAL이어서 SUM도 소수점 두 자리의 합계를 반환합니다. 이번 데이터에서 총액에 ROUND를 추가하지 않아도 결과 조건을 충족합니다.

---

## 문제 2. 월별 고액 거래 비율

### 테이블 설명

**bank\_transactions — 한 행은 금융 거래 한 건입니다.** 같은 고객이 같은 날짜에 여러 번 거래할 수 있습니다. 아래는 이번 문제에 필요한 컬럼 일부입니다.

| 컬럼명 | 자료형 | 의미 |
| --- | --- | --- |
| transaction\_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer\_id | VARCHAR(20) | 고객 ID |
| transaction\_date | DATE | 거래 날짜, 시각 없음 |
| transaction\_amount | DECIMAL(15,2) | 거래금액 |

위 컬럼에는 NULL이 없습니다. 데이터의 날짜 범위는 2016-08-01부터 2016-10-21까지입니다. 금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

연월별 전체 거래 건수, 거래금액 5000 이상인 고액 거래 건수와 비율을 조회합니다.

### 조건

- 전체 기간을 사용하고 연월은 YYYY-MM 형식입니다.
- 정확히 5000인 거래도 고액에 포함합니다.
- 고액 거래 비율(%) = 고액 거래 건수 / 전체 거래 건수 × 100.
- 비율은 소수점 둘째 자리까지 반올림합니다.
- 고액 거래가 없어도 거래 기록이 있는 연월을 포함하고 건수·비율을 0으로 표시합니다.
- 최소 거래 건수 조건 없이 거래 연월 오름차순 정렬합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| transaction\_month | 거래 연월 |
| transaction\_count | 전체 거래 건수 |
| high\_amount\_count | 5000 이상 거래 건수 |
| high\_amount\_rate | 고액 거래 비율(%) |

### 출력 예시 — 가상

| transaction\_month | transaction\_count | high\_amount\_count | high\_amount\_rate |
| --- | --- | --- | --- |
| 2016-08 | 200 | 20 | 10.00 |
| 2016-09 | 100 | 5 | 5.00 |
| 2016-10 | 50 | 0 | 0.00 |

### 예시 설명

200건 중 20건이 고액이면 10%입니다. 거래는 있지만 고액 거래가 없는 월도 포함합니다. 가상 예시입니다.

### 제출 쿼리

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    COUNT(*) AS transaction_count,
    COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END) AS high_amount_count,
    ROUND(
        COUNT(CASE WHEN transaction_amount >= 5000 THEN 1 END)
        / COUNT(*) * 100,
        2
    ) AS high_amount_rate
FROM bank_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;
```

### 검증

| transaction\_month | transaction\_count | high\_amount\_count | high\_amount\_rate |
| --- | --- | --- | --- |
| 2016-08 | 653933 | 35767 | 5.47 |
| 2016-09 | 390975 | 21446 | 5.49 |
| 2016-10 | 3659 | 246 | 6.72 |

실행 결과: 3 rows in set (1.40 sec).

### 핵심 개념 정리

고액 거래 건수와 비율의 분자는 같은 대상을 셉니다. 분모에는 해당 월의 모든 거래를 포함합니다. 실제 결과에는 고액 0건인 월이 없어 0건 예시는 실제 출력 검증과 구분합니다.

---

## 문제 3. 서로 다른 3일 이상 거래한 고객

### 테이블 설명

**bank\_transactions — 한 행은 금융 거래 한 건입니다.** 같은 고객이 같은 날짜에 여러 번 거래할 수 있습니다. 아래는 이번 문제에 필요한 컬럼 일부입니다.

| 컬럼명 | 자료형 | 의미 |
| --- | --- | --- |
| transaction\_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer\_id | VARCHAR(20) | 고객 ID |
| transaction\_date | DATE | 거래 날짜, 시각 없음 |
| transaction\_amount | DECIMAL(15,2) | 거래금액 |

위 컬럼에는 NULL이 없습니다. 데이터의 날짜 범위는 2016-08-01부터 2016-10-21까지입니다. 금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

서로 다른 3일 이상 거래한 고객의 ID, 전체 거래 건수, 거래 날짜 수, 총 거래금액을 조회합니다. 결과 한 행은 고객 한 명의 거래 통계입니다.

### 조건

- 전체 기간을 사용합니다.
- 같은 날짜에 여러 번 거래해도 거래 날짜 수는 1일입니다.
- 정확히 3일도 포함하며 연속일 필요가 없습니다.
- 거래 건수와 총액에는 같은 날 발생한 거래도 각각 포함합니다.
- 총액은 소수점 둘째 자리까지 반올림합니다.
- 거래 날짜 수 내림차순 → 총액 내림차순 → 고객 ID 오름차순으로 정렬합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer\_id | 고객 ID |
| transaction\_count | 전체 거래 건수 |
| active\_day\_count | 서로 다른 거래 날짜 수 |
| total\_transaction\_amount | 총 거래금액 |

### 출력 예시 — 가상

| customer\_id | transaction\_count | active\_day\_count | total\_transaction\_amount |
| --- | --- | --- | --- |
| CUSTOMER\_A | 5 | 4 | 8000.00 |
| CUSTOMER\_B | 6 | 3 | 12000.00 |
| CUSTOMER\_C | 3 | 3 | 5000.00 |

### 예시 설명

B가 8월1일 3건·8월3일 2건·8월7일 1건 거래했다면 거래 6건, 거래 날짜 3일입니다. 하루에 10건만 거래한 고객은 날짜가 1개라 제외합니다. 가상 예시입니다.

### 제출 쿼리

```sql
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT transaction_date) AS active_day_count,
    ROUND(SUM(transaction_amount), 2) AS total_transaction_amount
FROM bank_transactions
GROUP BY customer_id
HAVING active_day_count >= 3
ORDER BY active_day_count DESC, total_transaction_amount DESC, customer_id ASC;
```

### 검증 — 실제 출력 일부

| customer\_id | transaction\_count | active\_day\_count | total\_transaction\_amount |
| --- | --- | --- | --- |
| FIN_CUSTOMER_027 | 6 | 6 | 14758.39 |
| FIN_CUSTOMER_028 | 6 | 6 | 12800.00 |
| FIN_CUSTOMER_029 | 6 | 6 | 12027.00 |
| FIN_CUSTOMER_018 | 6 | 6 | 9796.03 |
| FIN_CUSTOMER_007 | 6 | 5 | 37873.00 |

첨부된 사용자 출력 중 일부입니다. 이 표를 전체 결과나 연속된 상위 5행으로 간주하지 않습니다. 첨부 출력에는 전체 행 수·실행 시간이 없어 해당 값은 확정하지 않습니다.

### 이해 확인

서로 다른 3일 이상은 연속된 3일을 뜻하지 않습니다. 같은 날의 여러 거래는 날짜 수로 한 번만 세며, 거래 건수와 금액 합계에는 모두 포함합니다.

### 핵심 개념 정리

C1113684는 거래 6건·거래 날짜 5일입니다. DATE 컬럼에는 시각이 없어 날짜 값을 직접 중복 제외하면 됩니다.
</details>

<details>
<summary>🧩 문제 4 — 서로 다른 3일 이상 거래한 고객 수</summary>

## 문제 4. 서로 다른 3일 이상 거래한 고객 수

### 테이블 설명

**bank\_transactions — 한 행은 금융 거래 한 건입니다.** 같은 고객이 같은 날짜에 여러 번 거래할 수 있습니다. 아래는 이번 문제에 필요한 컬럼 일부입니다.

| 컬럼명 | 자료형 | 의미 |
| --- | --- | --- |
| transaction\_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer\_id | VARCHAR(20) | 고객 ID |
| transaction\_date | DATE | 거래 날짜, 시각 없음 |
| transaction\_amount | DECIMAL(15,2) | 거래금액 |

위 컬럼에는 NULL이 없습니다. 데이터의 날짜 범위는 2016-08-01부터 2016-10-21까지입니다. 금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

전체 기간에서 서로 다른 3일 이상 거래한 고객이 몇 명인지 조회합니다. 최종 결과는 조건을 만족한 전체 고객 수 한 행입니다.

### 조건

- 같은 날짜 여러 거래는 날짜 수로 1일입니다.
- 정확히 3일도 포함하고 연속일 필요는 없습니다.
- 고객 목록이나 날짜 수 합계가 아니라 고객 수를 출력합니다.
- 대상 고객이 없으면 0입니다. 정렬 조건 없이 bank\_transactions만 사용합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| customer\_count | 조건을 만족한 고객 수 |

### 출력 예시 — 가상

| customer\_count |
| --- |
| 2 |

### 예시 설명

A의 날짜가 8월1일·1일·5일·20일, B는 8월2일·10일, C는 8월3일·8일·9월1일이면 A·C만 서로 다른 날짜 3개로 포함합니다. 가상 결과는 2명입니다.

### 제출 쿼리

```sql
SELECT COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT transaction_date) AS active_day_count,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING active_day_count >= 3
) AS active_customer_id;
```

### 검증

| customer\_count |
| --- |
| 17685 |

실행 결과: 1 row in set (2.12 sec). 업로드 전 읽기 전용 재집계도 동일한 고객 수를 반환했습니다.

### 핵심 개념 정리

안쪽은 고객별로 묶고 거래 날짜가 3개 이상인 고객만 남깁니다. 바깥은 이미 선별된 고객 행을 셉니다. 안쪽의 거래 건수·금액 합계는 최종 고객 수 계산에 필수는 아니지만 포함해도 결과는 맞습니다.
</details>

<details>
<summary>🧩 문제 5 — 대상 고객들의 누적 거래금액 평균</summary>

## 문제 5. 3일 이상 거래한 고객들의 누적 금액 평균

### 테이블 설명

**bank\_transactions — 한 행은 금융 거래 한 건입니다.** 같은 고객이 같은 날짜에 여러 번 거래할 수 있습니다. 아래는 이번 문제에 필요한 컬럼 일부입니다.

| 컬럼명 | 자료형 | 의미 |
| --- | --- | --- |
| transaction\_id | VARCHAR(20) | 거래 ID, 기본키 |
| customer\_id | VARCHAR(20) | 고객 ID |
| transaction\_date | DATE | 거래 날짜, 시각 없음 |
| transaction\_amount | DECIMAL(15,2) | 거래금액 |

위 컬럼에는 NULL이 없습니다. 데이터의 날짜 범위는 2016-08-01부터 2016-10-21까지입니다. 금액의 통화는 이번 기록에서 별도로 확정하지 않습니다.

### 문제

서로 다른 3일 이상 거래한 고객 각각의 누적 거래금액을 구하고 그 고객별 누적 금액들의 평균을 조회합니다. 고객마다 거래 건수·날짜 수가 달라도 같은 비중으로 반영합니다.

### 조건

- 전체 기간을 사용합니다.
- 같은 날짜의 여러 거래는 날짜 수로 1일이며 정확히 3일도 포함합니다. 날짜는 연속일 필요가 없습니다.
- 고객별 누적 금액에는 같은 날의 거래도 모두 합합니다.
- 고객별 합계는 중간 반올림하지 않고 최종 평균만 소수점 둘째 자리까지 반올림합니다.
- bank\_transactions만 사용하며 최종 결과 한 행, 정렬 없음입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| avg\_customer\_total | 대상 고객별 누적 거래금액의 평균 |

### 출력 예시 — 가상

| avg\_customer\_total |
| --- |
| 1500.00 |

### 예시 설명

A가 3일·총액1200, B가 5일·총액1800, C가 2일·총액3000이면 C는 제외합니다. A와 B의 총액을 같은 비중으로 평균 내면 (1200+1800)/2=1500입니다.

### 최종 제출 쿼리

```sql
SELECT ROUND(AVG(total_transaction_amount), 2) AS avg_customer_total
FROM (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT transaction_date) AS active_day_count,
        SUM(transaction_amount) AS total_transaction_amount
    FROM bank_transactions
    GROUP BY customer_id
    HAVING active_day_count >= 3
) AS active_customer;
```

### 검증

| avg\_customer\_total |
| --- |
| 4878.81 |

실행 결과: 1 row in set (1.75 sec). 업로드 전 읽기 전용 재집계도 동일한 평균을 반환했습니다.

### 결과 해석

문제 4의 대상 고객 17685명 각각의 전체 기간 총거래금액을 평균 낸 값입니다. **4878.81은 고객 한 명당 평균 누적 금액**이며 거래 한 건당·하루당 평균이 아닙니다.

### 핵심 개념 정리

active\_customer는 중간 표의 별칭이고 total\_transaction\_amount는 그 표의 금액 컬럼입니다. AVG는 표 이름 자체가 아니라 고객별 합계 컬럼을 읽습니다.
**해결 상태:** 최종 쿼리 정답·사용자 실행 확인. 평균 대상 컬럼과 표 별칭의 차이는 설명을 통해 점검했습니다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — COUNT·DISTINCT·집계 대상</summary>

## COUNT와 DISTINCT는 서로 다른 역할

| 표현 | 역할 |
| --- | --- |
| COUNT(\*) | 모든 행 수 |
| COUNT(transaction\_date) | NULL이 아닌 날짜 값 수. 반복 날짜도 셈 |
| COUNT(DISTINCT transaction\_date) | NULL을 제외하고 서로 다른 날짜를 한 번씩 셈 |

COUNT는 NULL이 아닌 값이면 0도 셉니다. DISTINCT는 값이 반복될 때 한 번만 반영합니다. COUNT(DISTINCT 컬럼)에도 0이 있으면 한 번 포함되므로 두 개념을 별개로 구분합니다.
예를 들어 날짜가 8월1일·8월1일·8월5일이면 거래는 3건이고 서로 다른 날짜는 2일입니다.

## 중간 결과의 한 행

원본 한 행은 거래 한 건입니다. 고객별 GROUP BY 이후 한 행은 고객 한 명입니다. HAVING으로 대상 고객을 남긴 뒤 바깥에서 COUNT 또는 AVG를 적용합니다.

| 문제 | 바깥 집계 대상 | 결과 |
| --- | --- | --- |
| 4 | 선별된 고객 행 수 | 17685명 |
| 5 | 그 고객들의 누적 거래금액 | 고객당 평균 4878.81 |

3일은 고객을 선별하는 기준이며 평균 금액을 3으로 나눌 이유가 아닙니다. 이 설명은 논리적 이해를 위한 흐름이지 DB의 물리적 실행 순서를 단정하는 것은 아닙니다.

## 표 별칭과 컬럼

FROM ( ... ) AS active\_customer에서 active\_customer는 표 이름입니다. 그 표 안에 만든 total\_transaction\_amount가 바깥 AVG의 대상입니다.
</details>

<details>
<summary>🧠 학습 회고·검증 범위·재풀이</summary>

## 문제별 상태

| 문제 | 확인된 결과 |
| --- | --- |
| 1 | 정답·3행 |
| 2 | 정답·3행 |
| 3 | 정답·공유된 실제 출력 확인 |
| 4 | 정답·17685명 |
| 5 | 정답·4878.81 |

5문제의 MySQL 실행 결과를 확인했고, 월별 집계와 문제 4·5는 읽기 전용 재집계로 대조했습니다.

## 다음 복습 — 미실행

- [ ] 거래 건수와 서로 다른 거래 날짜 수를 설명
- [ ] COUNT의 NULL 처리와 DISTINCT의 중복 제거를 구분
- [ ] 표 별칭과 평균 대상 컬럼을 구분
- [ ] 바깥 COUNT와 AVG가 읽는 대상을 설명
- [ ] 날짜 기준을 바꾼 문제를 답 없이 재작성
재풀이 결과를 확인하기 전까지 완료로 표시하지 않습니다.
</details>
</details>
