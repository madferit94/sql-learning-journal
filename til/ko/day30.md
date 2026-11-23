# Day 30 — 주가 다음 거래일 비교·거래량 이동평균

[English](../en/day30.md) · [목차](../../README.ko.md) · [SQL](../../sql/day30.sql)

MySQL 8.4 · market_study.daily_prices. 한 행은 종목 한 개의 거래일 하루입니다. 기본키는 (ticker, trade_date)이며 모든 원본 컬럼은 NULL이 아닙니다. 로컬 실습은 나스닥 과거 시세 5종목·64거래일씩, 총 320행을 사용했습니다. 공개 기록에는 SQL과 실제 실행 행 수를 싣고, 출력 모양은 가상 값으로 보여줍니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| ticker | VARCHAR(12) | 종목 코드 |
| trade_date | DATE | 기록된 거래일 |
| close_price | DECIMAL(14,6) | 종가, USD |
| volume | BIGINT UNSIGNED | 거래량, 주 |

MySQL에 접속한 뒤 `USE market_study;`를 실행합니다.

## 문제 1 — 코테형 · 종목별 다음 거래일 종가

같은 종목의 거래일 순서에서 다음으로 기록된 날의 종가를 붙입니다. 마지막 거래일도 남기고 다음 종가만 NULL로 둡니다. 전체에서 계산한 뒤 종목·거래일 오름차순으로 처음 20행을 출력합니다.

### 예상 출력 (가상 데이터)

| ticker | trade_date | close_price | next_close_price |
| --- | --- | --- | --- |
| AAA | 2026-08-07 | 100.00 | 103.00 |
| AAA | 2026-08-10 | 103.00 | NULL |

### 최종 기록 SQL

```sql
SELECT ticker, trade_date, close_price,
       LEAD(close_price) OVER (
           PARTITION BY ticker ORDER BY trade_date ASC
       ) AS next_close_price
FROM daily_prices
ORDER BY ticker ASC, trade_date ASC
LIMIT 20;
```

### 실행 확인

MySQL 재실행: 20행.

거래일 정렬은 다음 행을 정하고, LEAD의 인수는 가져올 값을 정합니다. 날짜를 인수로 쓰면 다음 날짜가 나오고, 종가를 쓰면 다음 종가가 나옵니다. LIMIT은 계산 뒤에 적용되므로 화면의 마지막 행에도 다음 종가가 있을 수 있습니다.

## 문제 2 — 실무형 · 다음 거래일 종가가 3% 이상 움직인 기록

공시나 뉴스를 추가로 확인할 후보를 찾습니다. (다음 종가 − 현재 종가) ÷ 현재 종가 × 100의 절댓값이 3 이상인 날을 남깁니다. 다음 거래일이 없으면 제외합니다. 반올림 전 변동 폭 내림차순, 종목·거래일 오름차순으로 최대 20행을 표시합니다. 출력용 변동률에는 부호를 유지하고 두 자리로 반올림합니다.

### 예상 출력 (가상 데이터)

| ticker | trade_date | next_trade_date | close_price | next_close_price | next_day_change_pct |
| --- | --- | --- | --- | --- | --- |
| AAA | 2026-08-07 | 2026-08-10 | 100.00 | 96.00 | -4.00 |
| BBB | 2026-08-07 | 2026-08-10 | 80.00 | 82.40 | 3.00 |

### 최종 기록 SQL

```sql
WITH next_trade AS (
    SELECT ticker, trade_date, close_price,
           LEAD(trade_date) OVER w AS next_trade_date,
           LEAD(close_price) OVER w AS next_close_price
    FROM daily_prices
    WINDOW w AS (PARTITION BY ticker ORDER BY trade_date ASC)
)
SELECT ticker, trade_date, next_trade_date, close_price, next_close_price,
       ROUND((next_close_price - close_price) / close_price * 100, 2)
           AS next_day_change_pct
FROM next_trade
WHERE ABS((next_close_price - close_price) / close_price * 100) >= 3
ORDER BY ABS((next_close_price - close_price) / close_price * 100) DESC,
         ticker ASC, trade_date ASC
LIMIT 20;
```

### 실행 확인

MySQL 재실행: 20행.

두 LEAD의 정렬 방향을 일치시켜 날짜와 종가가 같은 행을 가리키게 합니다. ABS는 필터와 정렬에만 사용합니다. 터미널 기록에 코드 블록 표식이 섞였으므로 첨부 실행표만으로 WHERE 적용 여부를 확정하지 않고, 표식을 뺀 쿼리를 별도 재실행했습니다.

## 문제 3 — 실무형 · 직전 5거래일 평균보다 거래량이 두 배 이상인 날

같은 종목의 당일을 뺀 직전 5거래일 평균 거래량을 구합니다. 직전 기록이 5개 미만이거나 평균이 0인 날은 제외합니다. 당일 거래량 ÷ 평균이 2 이상인 날만 남깁니다. 반올림 전 배수 내림차순, 종목·거래일 오름차순으로 최대 20행을 표시합니다. 평균과 배수의 반올림은 출력에만 적용합니다.

### 예상 출력 (가상 데이터)

| ticker | trade_date | volume | avg_volume_prev_5 | volume_ratio |
| --- | --- | --- | --- | --- |
| AAA | 2026-08-10 | 2600 | 1000.00 | 2.60 |
| BBB | 2026-08-11 | 1800 | 900.00 | 2.00 |

### 최종 기록 SQL

```sql
WITH avg_ticker AS (
    SELECT ticker, trade_date, volume,
           AVG(volume) OVER w AS avg_volume_prev_5,
           COUNT(*) OVER w AS prev_day_count
    FROM daily_prices
    WINDOW w AS (
        PARTITION BY ticker ORDER BY trade_date
        ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
    )
)
SELECT ticker, trade_date, volume,
       ROUND(avg_volume_prev_5, 2) AS avg_volume_prev_5,
       ROUND(volume / avg_volume_prev_5, 2) AS volume_ratio
FROM avg_ticker
WHERE prev_day_count = 5
  AND avg_volume_prev_5 > 0
  AND volume / avg_volume_prev_5 >= 2
ORDER BY volume / avg_ticker.avg_volume_prev_5 DESC, ticker ASC, trade_date ASC
LIMIT 20;
```

### 실행 확인

MySQL 재실행: 7행.

당일을 뺀 5행 범위는 ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING입니다. AVG만으로는 1~4행도 평균에 들어가므로 같은 범위에서 COUNT로 5행을 확인합니다. ROUND(1.54)는 2가 되므로, 필터에 넣으면 2배 미만도 들어옵니다. 정렬은 CTE의 반올림 전 평균을 명시적으로 참조합니다.

## 복습

복습할 때는 완성 쿼리를 보기 전에 종목과 날짜로 중간 표를 먼저 확인합니다. 다음 값 비교는 가져올 컬럼을, 이동평균은 시작·끝과 행 수를, 마지막에는 조건 판단에 쓸 값과 표시용 값을 구분합니다.
