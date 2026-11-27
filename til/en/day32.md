# Day 32 — General hospital records: LEFT JOIN, citywide shares, and running totals

[한국어](../ko/day32.md) · [Index](../../README.md) · [SQL](../../sql/day32.sql)

2026-11-27 · MySQL 8.4 · `health_study.facilities`

The dataset covers 25 Seoul districts in the [HIRA healthcare facility register](https://www.data.go.kr/data/15051057/fileData.do) at the end of 2025. One row is one facility reporting record. The counts and shares describe this snapshot.

| Column | Type | Meaning |
| --- | --- | --- |
| source_row_id | INT UNSIGNED | Source row number and primary key. Not nullable. |
| district | VARCHAR(60) | Seoul district. Not nullable. |
| facility_type | VARCHAR(50) | Reported facility type. Not nullable. |

```sql
USE health_study;
SHOW COLUMNS FROM facilities;
```

## Exercise 1 — Count general hospital records, including districts with zero

Keep all 25 Seoul districts and count records whose facility type is exactly `종합병원` (general hospital). Exclude `상급종합병원` (tertiary hospital). Show zero for districts with no match. Return one row per district, sorted by count descending and district name ascending.

### Example input (illustrative)

| source_row_id | district | facility_type |
| --- | --- | --- |
| 1 | A구 | 종합병원 |
| 2 | A구 | 종합병원 |
| 3 | B구 | 종합병원 |
| 4 | B구 | 상급종합병원 |
| 5 | C구 | 의원 |

### Expected output (illustrative)

| district | general_hospital_count |
| --- | --- |
| A구 | 2 |
| B구 | 1 |
| C구 | 0 |

### Final query recorded in the journal

```sql
WITH districts AS (
    SELECT DISTINCT district
    FROM facilities
)
SELECT d.district,
       COUNT(f.source_row_id) AS general_hospital_count
FROM districts AS d
LEFT JOIN facilities AS f
    ON d.district = f.district
   AND f.facility_type = '종합병원'
GROUP BY d.district
ORDER BY general_hospital_count DESC, district ASC;
```

### Recorded output (25 rows)

| district | general_hospital_count |
| --- | --- |
| 영등포구 | 7 |
| 강서구 | 4 |
| 강동구 | 3 |
| 노원구 | 3 |
| 동대문구 | 3 |
| 중랑구 | 3 |
| 강남구 | 2 |
| 강북구 | 2 |
| 양천구 | 2 |
| 은평구 | 2 |
| 종로구 | 2 |
| 관악구 | 1 |
| 광진구 | 1 |
| 구로구 | 1 |
| 금천구 | 1 |
| 도봉구 | 1 |
| 동작구 | 1 |
| 서대문구 | 1 |
| 서초구 | 1 |
| 성동구 | 1 |
| 송파구 | 1 |
| 용산구 | 1 |
| 중구 | 1 |
| 마포구 | 0 |
| 성북구 | 0 |

### Calculation and verification

The query uses the distinct district list on the left and joins the source by `district`. The facility-type condition in `ON` keeps unmatched districts. `COUNT(f.source_row_id)` skips the NULL values on the unmatched rows and returns zero. `COUNT(*)` would count each preserved row as one. Mapo-gu and Seongbuk-gu both returned zero.

## Exercise 2 — Calculate each district’s share of the Seoul total

Add the Seoul total and district share to the counts. The percentage is the district count divided by the Seoul total and multiplied by 100. Show two decimal places and return NULL if the city total is zero. Keep the same districts and sort order as Exercise 1.

### Example input (illustrative)

| district | general_hospital_count |
| --- | --- |
| A구 | 2 |
| B구 | 1 |
| C구 | 0 |

### Expected output (illustrative)

| district | general_hospital_count | seoul_total_count | share_pct |
| --- | --- | --- | --- |
| A구 | 2 | 3 | 66.67 |
| B구 | 1 | 3 | 33.33 |
| C구 | 0 | 3 | 0.00 |

### Final query recorded in the journal

```sql
WITH districts AS (
    SELECT DISTINCT district,
           COUNT(CASE WHEN facility_type = '종합병원' THEN 1 END)
               AS general_hospital_count
    FROM facilities
    GROUP BY district
),
hospitals AS (
    SELECT district, general_hospital_count,
           SUM(general_hospital_count) OVER () AS seoul_total_count
    FROM districts
)
SELECT district, general_hospital_count, seoul_total_count,
       ROUND(general_hospital_count / NULLIF(seoul_total_count, 0) * 100, 2)
           AS share_pct
FROM hospitals
ORDER BY general_hospital_count DESC, district ASC;
```

### Recorded output (25 rows)

| district | general_hospital_count | seoul_total_count | share_pct |
| --- | --- | --- | --- |
| 영등포구 | 7 | 45 | 15.56 |
| 강서구 | 4 | 45 | 8.89 |
| 강동구 | 3 | 45 | 6.67 |
| 노원구 | 3 | 45 | 6.67 |
| 동대문구 | 3 | 45 | 6.67 |
| 중랑구 | 3 | 45 | 6.67 |
| 강남구 | 2 | 45 | 4.44 |
| 강북구 | 2 | 45 | 4.44 |
| 양천구 | 2 | 45 | 4.44 |
| 은평구 | 2 | 45 | 4.44 |
| 종로구 | 2 | 45 | 4.44 |
| 관악구 | 1 | 45 | 2.22 |
| 광진구 | 1 | 45 | 2.22 |
| 구로구 | 1 | 45 | 2.22 |
| 금천구 | 1 | 45 | 2.22 |
| 도봉구 | 1 | 45 | 2.22 |
| 동작구 | 1 | 45 | 2.22 |
| 서대문구 | 1 | 45 | 2.22 |
| 서초구 | 1 | 45 | 2.22 |
| 성동구 | 1 | 45 | 2.22 |
| 송파구 | 1 | 45 | 2.22 |
| 용산구 | 1 | 45 | 2.22 |
| 중구 | 1 | 45 | 2.22 |
| 마포구 | 0 | 45 | 0.00 |
| 성북구 | 0 | 45 | 0.00 |

### Calculation and verification

The first draft used all facility records for `general_hospital_count` and labeled a district-level conditional count as `seoul_total_count`. Both counts were grouped by district. The second draft attempted to sum the district name. The final query applies `SUM(general_hospital_count) OVER ()` to the district counts. The empty window specification uses the entire result set, keeping one row per district. `NULLIF(seoul_total_count, 0)` yields NULL when the denominator is zero.

## Exercise 3 — Compute running counts and cumulative shares in descending count order

Add the counts from the first district through the current district, starting with the highest counts. Break ties by district name ascending and use the same display order. Calculate the cumulative percentage against the Seoul total, round to two decimal places, and retain zero-count districts. Return a NULL percentage if the city total is zero.

### Example input (illustrative)

| district | general_hospital_count |
| --- | --- |
| A구 | 4 |
| B구 | 2 |
| C구 | 2 |
| D구 | 0 |

### Expected output (illustrative)

| district | general_hospital_count | cumulative_count | seoul_total_count | cumulative_share_pct |
| --- | --- | --- | --- | --- |
| A구 | 4 | 4 | 8 | 50.00 |
| B구 | 2 | 6 | 8 | 75.00 |
| C구 | 2 | 8 | 8 | 100.00 |
| D구 | 0 | 8 | 8 | 100.00 |

### Final query recorded in the journal

```sql
WITH districts AS (
    SELECT DISTINCT district,
           COUNT(CASE WHEN facility_type = '종합병원' THEN 1 END)
               AS general_hospital_count
    FROM facilities
    GROUP BY district
),
hospitals AS (
    SELECT district, general_hospital_count,
           SUM(general_hospital_count) OVER (
               ORDER BY general_hospital_count DESC, district ASC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_count,
           SUM(general_hospital_count) OVER () AS seoul_total_count
    FROM districts
)
SELECT district, general_hospital_count, cumulative_count, seoul_total_count,
       ROUND(cumulative_count / NULLIF(seoul_total_count, 0) * 100, 2)
           AS cumulative_share_pct
FROM hospitals
ORDER BY general_hospital_count DESC, district ASC;
```

### Recorded output (25 rows)

| district | general_hospital_count | cumulative_count | seoul_total_count | cumulative_share_pct |
| --- | --- | --- | --- | --- |
| 영등포구 | 7 | 7 | 45 | 15.56 |
| 강서구 | 4 | 11 | 45 | 24.44 |
| 강동구 | 3 | 14 | 45 | 31.11 |
| 노원구 | 3 | 17 | 45 | 37.78 |
| 동대문구 | 3 | 20 | 45 | 44.44 |
| 중랑구 | 3 | 23 | 45 | 51.11 |
| 강남구 | 2 | 25 | 45 | 55.56 |
| 강북구 | 2 | 27 | 45 | 60.00 |
| 양천구 | 2 | 29 | 45 | 64.44 |
| 은평구 | 2 | 31 | 45 | 68.89 |
| 종로구 | 2 | 33 | 45 | 73.33 |
| 관악구 | 1 | 34 | 45 | 75.56 |
| 광진구 | 1 | 35 | 45 | 77.78 |
| 구로구 | 1 | 36 | 45 | 80.00 |
| 금천구 | 1 | 37 | 45 | 82.22 |
| 도봉구 | 1 | 38 | 45 | 84.44 |
| 동작구 | 1 | 39 | 45 | 86.67 |
| 서대문구 | 1 | 40 | 45 | 88.89 |
| 서초구 | 1 | 41 | 45 | 91.11 |
| 성동구 | 1 | 42 | 45 | 93.33 |
| 송파구 | 1 | 43 | 45 | 95.56 |
| 용산구 | 1 | 44 | 45 | 97.78 |
| 중구 | 1 | 45 | 45 | 100.00 |
| 마포구 | 0 | 45 | 45 | 100.00 |
| 성북구 | 0 | 45 | 45 | 100.00 |

### Calculation and verification

The first run accumulated counts in district-name order, then displayed rows in descending count order. Yeongdeungpo-gu came first on screen with 7 records and a running count of 36. The final window sorts by count descending and district name ascending so ties are processed in a predictable order. `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` includes the first row through the current row. The outer ORDER BY displays rows in the same sequence.

## Understanding check and verification

1. Which key connects the district list to the facility records from the same source?
2. How many rows does `SUM() OVER ()` add when the input contains one row per district?
3. What does each ORDER BY control inside the window and at the end of the query?

A separate MySQL run matched the submitted output. Each query returns 25 rows with the same district counts. The citywide total is 45, the first six districts contribute 23 records (51.11%), and the final running count is 45 (100.00%).
