# Day 30 — Stock prices: next-session comparisons and moving averages

[한국어](../ko/day30.md) · [Index](../../README.md) · [SQL](../../sql/day30.sql)

MySQL 8.4 · market_study.daily_prices. Each row is one security on one trading date. The primary key is (ticker, trade_date); all source columns are non-NULL. The local Nasdaq historical-price practice snapshot contains 320 rows: five stocks over 64 trading dates each. The public record includes SQL and actual result counts; all example rows use hypothetical values.

| Column | Type | Meaning |
| --- | --- | --- |
| ticker | VARCHAR(12) | Stock symbol |
| trade_date | DATE | Observed trading date |
| close_price | DECIMAL(14,6) | Closing price in USD |
| volume | BIGINT UNSIGNED | Trading volume in shares |

After connecting to MySQL, run `USE market_study;`.

## Exercise 1 — Coding-test style · Next closing price by stock

Attach the closing price of the next observed session for the same stock. Keep each stock’s final row, with NULL for the next price. Compute over all rows, then show the first 20 sorted by ticker and trading date ascending.

### Expected output shape (hypothetical)

| ticker | trade_date | close_price | next_close_price |
| --- | --- | --- | --- |
| AAA | 2026-08-07 | 100.00 | 103.00 |
| AAA | 2026-08-10 | 103.00 | NULL |

### Final query recorded in the journal

```sql
SELECT ticker, trade_date, close_price,
       LEAD(close_price) OVER (
           PARTITION BY ticker ORDER BY trade_date ASC
       ) AS next_close_price
FROM daily_prices
ORDER BY ticker ASC, trade_date ASC
LIMIT 20;
```

### Follow-up verification

MySQL recheck: 20 rows.

Window ordering chooses the next row; the argument to LEAD chooses the value to retrieve. Passing the date returns a date, passing the closing price returns a price. LIMIT comes after the calculation, so the last displayed row may still have a next value.

## Exercise 2 — Workplace style · Next-session moves of at least 3%

Build a list for news or disclosure follow-up. Keep moves where the absolute value of (next close − current close) ÷ current close × 100 is at least 3. Exclude rows with no later session. Sort by unrounded magnitude descending, then ticker and date ascending; return up to 20 rows. Keep the sign and round to two decimals only for display.

### Expected output shape (hypothetical)

| ticker | trade_date | next_trade_date | close_price | next_close_price | next_day_change_pct |
| --- | --- | --- | --- | --- | --- |
| AAA | 2026-08-07 | 2026-08-10 | 100.00 | 96.00 | -4.00 |
| BBB | 2026-08-07 | 2026-08-10 | 80.00 | 82.40 | 3.00 |

### Final query recorded in the journal

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

### Follow-up verification

MySQL recheck: 20 rows.

Use identical ordering in both LEAD calls so the next date and next price refer to the same row. Use ABS for filtering and sorting only. The pasted terminal transcript contained Markdown fence markers, so it did not establish that WHERE ran. The clean SQL was checked separately.

## Exercise 3 — Workplace style · Volume at least twice the previous five-session average

Compute the mean trading volume of the previous five observed sessions for the same stock, excluding the current session. Exclude dates with fewer than five observations or a zero mean. Keep current volume divided by the mean at least 2. Sort by the unrounded ratio descending, then ticker and date ascending; return up to 20 rows. Round only the displayed mean and ratio.

### Expected output shape (hypothetical)

| ticker | trade_date | volume | avg_volume_prev_5 | volume_ratio |
| --- | --- | --- | --- | --- |
| AAA | 2026-08-10 | 2600 | 1000.00 | 2.60 |
| BBB | 2026-08-11 | 1800 | 900.00 | 2.00 |

### Final query recorded in the journal

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

### Follow-up verification

MySQL recheck: 7 rows.

ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING excludes the current row. AVG can use only one to four prior rows, so use COUNT over the same frame to enforce five. ROUND(1.54) gives 2, so using it in the filter could admit rows below the threshold. The sort explicitly references the unrounded mean from the CTE.

## Review

Before rereading the final query, inspect a small intermediate result for one ticker. Identify the value to retrieve, the frame boundaries and row count, and which values are for decisions versus display.
