# Day 32 — 종합병원 신고 기록 · LEFT JOIN · 전체 비중과 누적합

[English](../en/day32.md) · [목차](../../README.ko.md) · [SQL](../../sql/day32.sql)

2026-11-27 · MySQL 8.4 · `health_study.facilities`

[심평원 요양기관 개설 현황](https://www.data.go.kr/data/15051057/fileData.do)의 2025년 말 스냅샷 중 서울 25개 구를 사용합니다. 한 행은 의료기관 신고 기록 한 줄입니다. 이 결과는 신고 스냅샷의 건수와 비중입니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT UNSIGNED | 원본 행 번호이자 기본키. NULL 불가 |
| district | VARCHAR(60) | 서울 자치구. NULL 불가 |
| facility_type | VARCHAR(50) | 신고된 기관 종류. NULL 불가 |

```sql
USE health_study;
SHOW COLUMNS FROM facilities;
```

## 문제 1 — 종합병원 신고 기록이 없는 구까지 집계

서울 25개 구를 모두 남기고, 기관 종류가 정확히 `종합병원`인 신고 기록을 구별로 셉니다. `상급종합병원`은 제외하고, 해당 기록이 없는 구는 0건으로 표시합니다. 구당 한 행을 출력하고 건수 내림차순, 동률이면 구 이름 오름차순으로 정렬합니다.

### 입력 예시 (가상)

| source_row_id | district | facility_type |
| --- | --- | --- |
| 1 | A구 | 종합병원 |
| 2 | A구 | 종합병원 |
| 3 | B구 | 종합병원 |
| 4 | B구 | 상급종합병원 |
| 5 | C구 | 의원 |

### 예상 출력 (가상)

| district | general_hospital_count |
| --- | --- |
| A구 | 2 |
| B구 | 1 |
| C구 | 0 |

### 최종 기록 SQL

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

### 실제 결과 (25행)

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

### 계산과 검증

전체 구 목록을 왼쪽에 두고 `district`로 원본을 연결했습니다. 오른쪽의 기관 종류 조건을 `ON`에 두어 매칭이 없는 구도 살렸습니다. `COUNT(f.source_row_id)`는 오른쪽이 NULL인 행을 세지 않아 0을 반환합니다. `COUNT(*)`를 쓰면 매칭 없이 남은 행도 1건으로 셉니다. 마포구와 성북구가 0건으로 남았습니다.

## 문제 2 — 서울 전체 종합병원 신고 기록 중 각 구의 비중

구별 건수에 서울 전체 건수와 각 구의 비중을 붙입니다. 비중은 구별 건수 ÷ 서울 전체 건수 × 100이며 소수 둘째 자리까지 표시합니다. 전체가 0건이면 비중은 NULL로 표시합니다. 행 범위와 정렬은 1번과 같습니다.

### 입력 예시 (가상)

| district | general_hospital_count |
| --- | --- |
| A구 | 2 |
| B구 | 1 |
| C구 | 0 |

### 예상 출력 (가상)

| district | general_hospital_count | seoul_total_count | share_pct |
| --- | --- | --- | --- |
| A구 | 2 | 3 | 66.67 |
| B구 | 1 | 3 | 33.33 |
| C구 | 0 | 3 | 0.00 |

### 최종 기록 SQL

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

### 실제 결과 (25행)

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

### 계산과 검증

첫 초안은 전체 의료기관 기록에 `general_hospital_count`를, 구별 종합병원 기록에 `seoul_total_count`를 붙였습니다. 두 집계 모두 `GROUP BY district`의 영향을 받습니다. 두 번째 초안의 `SUM(district)`는 구 이름을 더하려고 했습니다. 최종 쿼리는 조건부 COUNT로 구별 종합병원 건수를 만든 뒤 `SUM(general_hospital_count) OVER ()`로 25행 전체의 합을 각 행에 붙입니다. 빈 `OVER ()`는 전체 결과를 하나의 계산 범위로 씁니다. `NULLIF(seoul_total_count, 0)`는 전체가 0건일 때 분모를 NULL로 바꿉니다.

## 문제 3 — 신고 건수 내림차순 누적합과 누적 비중

구별 건수가 많은 구부터 현재 구까지 순서대로 더합니다. 동률은 구 이름 오름차순으로 처리하고, 최종 출력에도 같은 순서를 적용합니다. 누적 비중은 누적 건수 ÷ 서울 전체 건수 × 100이며 소수 둘째 자리까지 표시합니다. 전체가 0건이면 비중은 NULL로 표시하고 0건인 구도 남깁니다.

### 입력 예시 (가상)

| district | general_hospital_count |
| --- | --- |
| A구 | 4 |
| B구 | 2 |
| C구 | 2 |
| D구 | 0 |

### 예상 출력 (가상)

| district | general_hospital_count | cumulative_count | seoul_total_count | cumulative_share_pct |
| --- | --- | --- | --- | --- |
| A구 | 4 | 4 | 8 | 50.00 |
| B구 | 2 | 6 | 8 | 75.00 |
| C구 | 2 | 8 | 8 | 100.00 |
| D구 | 0 | 8 | 8 | 100.00 |

### 최종 기록 SQL

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

### 실제 결과 (25행)

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

### 계산과 검증

첫 실행에서는 윈도우 안에서 구 이름순으로 더한 뒤 바깥에서 건수순으로 표시해, 첫 줄 영등포구가 7건인데 누적은 36건이었습니다. 윈도우 안의 ORDER BY에 건수 내림차순과 구 이름 오름차순을 적용했습니다. 건수가 같은 구에는 구 이름으로 일정한 순서를 부여합니다. `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`는 첫 행부터 현재 행까지를 계산 범위로 잡습니다. 최종 ORDER BY에는 같은 기준을 써서 계산 순서대로 출력했습니다.

## 이해 점검·검증 범위

1. 하나의 원본에서 만든 구 목록과 시설 기록은 어떤 키로 연결하나요?
2. 구당 한 행인 결과에서 `SUM() OVER ()`는 몇 행을 더하나요?
3. 윈도우 안의 ORDER BY와 맨 마지막 ORDER BY는 각각 무엇을 정하나요?

제출 결과와 별도 MySQL 재실행을 대조했습니다. 세 문제 모두 25행이고 구별 건수가 일치합니다. 전체 45건, 상위 6개 구 누적 23건(51.11%), 최종 누적 45건(100.00%)을 확인했습니다.
