-- Day30: three stock-market SQL exercises.
USE market_study;

-- Question 1
SELECT ticker, trade_date, close_price,
       LEAD(close_price) OVER (
           PARTITION BY ticker ORDER BY trade_date ASC
       ) AS next_close_price
FROM daily_prices
ORDER BY ticker ASC, trade_date ASC
LIMIT 20;

-- Question 2
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

-- Question 3
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
