# Day 31 — Healthcare facility records, missing IDs, and specialty shares

[한국어](../ko/day31.md) · [Index](../../README.md) · [SQL](../../sql/day31.sql)

MySQL 8.4 · health_study.facilities. This session uses 25,405 records from 25 Seoul districts in the year-end 2025 [HIRA facility snapshot](https://www.data.go.kr/data/15051057/fileData.do). Each row is one source filing record. In 165 rows an explanatory note occupies the ID field, so facility_id is NULL and the note is retained in source_id_note. These are neither a current operating-facility register nor patient records.

| Column | Type | Meaning |
| --- | --- | --- |
| source_row_id | INT UNSIGNED | Source row number, primary key |
| district | VARCHAR(60) | Seoul district, NOT NULL |
| facility_type | VARCHAR(50) | Facility type, NOT NULL |
| facility_id | VARCHAR(160) | Encrypted facility ID; NULL where the source has a note instead |
| displayed_specialty | VARCHAR(100) | Reported specialty, nullable |

Run this after connecting to MySQL.

```sql
USE health_study;
SHOW COLUMNS FROM facilities;
```

## Shared input example (hypothetical data)

| source_row_id | district | facility_type | facility_id | displayed_specialty |
| --- | --- | --- | --- | --- |
| 1 | A구 | 의원 | F001 | 소아청소년과 |
| 2 | A구 | 의원 | NULL | 내과 |
| 3 | A구 | 약국 | F003 | 해당사항없음 |
| 4 | B구 | 의원 | F004 | 내과 |
| 5 | B구 | 치과의원 | F005 | 치과 |

## Exercise 1 — Clinic records by district

Count records whose type is exactly 의원 (clinic), including clinics with NULL IDs. Return one row per district with a clinic, ordered by count descending and district ascending.

### Expected output (hypothetical data)

| district | clinic_count |
| --- | --- |
| A구 | 2 |
| B구 | 1 |

### Final query recorded in the journal

```sql
SELECT district, COUNT(*) AS clinic_count
FROM facilities
WHERE facility_type = '의원'
GROUP BY district
ORDER BY clinic_count DESC, district ASC;
```

### Recorded output (25 rows)

The recorded result was checked with a separate local MySQL run.

| district | clinic_count |
| --- | --- |
| 강남구 | 2109 |
| 서초구 | 956 |
| 송파구 | 660 |
| 강서구 | 491 |
| 강동구 | 477 |
| 마포구 | 433 |
| 영등포구 | 431 |
| 노원구 | 401 |
| 관악구 | 361 |
| 은평구 | 340 |
| 양천구 | 333 |
| 광진구 | 315 |
| 중구 | 309 |
| 구로구 | 305 |
| 동작구 | 296 |
| 동대문구 | 288 |
| 성북구 | 271 |
| 중랑구 | 269 |
| 성동구 | 253 |
| 강북구 | 243 |
| 서대문구 | 214 |
| 종로구 | 204 |
| 금천구 | 175 |
| 도봉구 | 175 |
| 용산구 | 168 |

### Calculation and checks

COUNT(*) counts rows even if their IDs are NULL. The 25 districts had 10,477 clinic records in total.

## Exercise 2 — Missing facility IDs by district

To prioritize data checks, show each district’s total records, missing-ID records and missing-ID percentage across all facility types. Retain districts with zero missing IDs. Display missing count ÷ total count × 100 to two decimals. Sort by missing count descending, then district ascending.

### Expected output (hypothetical data)

| district | total_record_count | missing_id_count | missing_id_rate |
| --- | --- | --- | --- |
| A구 | 3 | 1 | 33.33 |
| B구 | 2 | 0 | 0.00 |

### Final query recorded in the journal

```sql
WITH record_fac AS (
    SELECT district,
           COUNT(*) AS total_record_count,
           COUNT(CASE WHEN facility_id IS NULL THEN 1 END) AS missing_id_count
    FROM facilities
    GROUP BY district
)
SELECT district, total_record_count, missing_id_count,
       ROUND(missing_id_count / total_record_count * 100, 2) AS missing_id_rate
FROM record_fac
ORDER BY missing_id_count DESC, district ASC;
```

### Recorded output (25 rows)

No terminal output was supplied for Question 2; the table below comes from a separate local MySQL run.

| district | total_record_count | missing_id_count | missing_id_rate |
| --- | --- | --- | --- |
| 강남구 | 3646 | 32 | 0.88 |
| 서초구 | 1884 | 18 | 0.96 |
| 송파구 | 1705 | 13 | 0.76 |
| 강동구 | 1264 | 9 | 0.71 |
| 관악구 | 965 | 8 | 0.83 |
| 노원구 | 1004 | 8 | 0.80 |
| 성북구 | 765 | 8 | 1.05 |
| 은평구 | 950 | 8 | 0.84 |
| 중구 | 786 | 7 | 0.89 |
| 강서구 | 1271 | 6 | 0.47 |
| 광진구 | 800 | 6 | 0.75 |
| 마포구 | 1016 | 6 | 0.59 |
| 성동구 | 647 | 5 | 0.77 |
| 영등포구 | 1135 | 5 | 0.44 |
| 종로구 | 668 | 5 | 0.75 |
| 강북구 | 643 | 3 | 0.47 |
| 구로구 | 818 | 3 | 0.37 |
| 중랑구 | 761 | 3 | 0.39 |
| 금천구 | 516 | 2 | 0.39 |
| 도봉구 | 508 | 2 | 0.39 |
| 동작구 | 818 | 2 | 0.24 |
| 양천구 | 895 | 2 | 0.22 |
| 용산구 | 445 | 2 | 0.45 |
| 동대문구 | 883 | 1 | 0.11 |
| 서대문구 | 612 | 1 | 0.16 |

### Calculation and checks

CASE WHEN can evaluate a predicate such as facility_id IS NULL. It returns 1 for a missing ID and, with ELSE omitted, NULL otherwise. COUNT ignores NULL but counts 0, so ELSE 0 would change the result. Filtering to missing records in WHERE would lose the total denominator and districts with zero missing records. The district counts sum to 165 missing IDs.

## Exercise 3 — Share of clinics listing pediatrics

For follow-up, compare all clinic records with clinic records whose reported specialty is exactly 소아청소년과 (pediatrics). Keep districts that have clinics but no pediatrics records. Display pediatric clinic count ÷ all clinic records × 100 to two decimals. Sort by pediatric count ascending, then district ascending.

### Expected output (hypothetical data)

| district | clinic_count | pediatric_clinic_count | pediatric_clinic_rate |
| --- | --- | --- | --- |
| B구 | 1 | 0 | 0.00 |
| A구 | 2 | 1 | 50.00 |

### Final query recorded in the journal

```sql
WITH pediatric AS (
    SELECT district, COUNT(*) AS clinic_count,
           COUNT(CASE WHEN displayed_specialty = '소아청소년과' THEN 1 END)
               AS pediatric_clinic_count
    FROM facilities
    WHERE facility_type = '의원'
    GROUP BY district
)
SELECT district, clinic_count, pediatric_clinic_count,
       ROUND(pediatric_clinic_count / clinic_count * 100, 2) AS pediatric_clinic_rate
FROM pediatric
ORDER BY pediatric_clinic_count ASC, district ASC;
```

### Recorded output (25 rows)

The recorded result was checked with a separate local MySQL run.

| district | clinic_count | pediatric_clinic_count | pediatric_clinic_rate |
| --- | --- | --- | --- |
| 종로구 | 204 | 4 | 1.96 |
| 중구 | 309 | 4 | 1.29 |
| 강북구 | 243 | 8 | 3.29 |
| 용산구 | 168 | 9 | 5.36 |
| 금천구 | 175 | 10 | 5.71 |
| 서대문구 | 214 | 10 | 4.67 |
| 도봉구 | 175 | 12 | 6.86 |
| 구로구 | 305 | 16 | 5.25 |
| 동대문구 | 288 | 16 | 5.56 |
| 중랑구 | 269 | 16 | 5.95 |
| 광진구 | 315 | 17 | 5.40 |
| 동작구 | 296 | 17 | 5.74 |
| 마포구 | 433 | 17 | 3.93 |
| 성북구 | 271 | 17 | 6.27 |
| 관악구 | 361 | 18 | 4.99 |
| 성동구 | 253 | 19 | 7.51 |
| 은평구 | 340 | 19 | 5.59 |
| 서초구 | 956 | 21 | 2.20 |
| 영등포구 | 431 | 21 | 4.87 |
| 양천구 | 333 | 23 | 6.91 |
| 노원구 | 401 | 24 | 5.99 |
| 강동구 | 477 | 25 | 5.24 |
| 강서구 | 491 | 29 | 5.91 |
| 강남구 | 2109 | 38 | 1.80 |
| 송파구 | 660 | 38 | 5.76 |

### Calculation and checks

The denominator is every clinic record retained by WHERE facility_type = '의원'. The numerator is the subset with pediatrics as its reported specialty, counted with CASE WHEN. Putting the specialty predicate in WHERE would remove other clinics from the denominator. All 25 district denominators match Question 1. This share describes the reported specialty, not actual access or care availability.

## Review

Define the eligible rows first, then count the subset within them. Check Question 1 against Question 3, and reconcile the counts and missing IDs in Question 2 against the source totals.
