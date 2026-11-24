# Day 31 — 의료기관 신고 기록·ID 누락·표시과목 비중

[English](../en/day31.md) · [목차](../../README.ko.md) · [SQL](../../sql/day31.sql)

MySQL 8.4 · health_study.facilities. [심평원 요양기관 개설 현황](https://www.data.go.kr/data/15051057/fileData.do)의 2025년 말 스냅샷 중 서울 25개 구의 25,405행을 사용합니다. 한 행은 원본 기관 신고 기록 한 줄입니다. 원본의 165행은 기관 ID 칸에 안내 문구가 있어 facility_id는 NULL, 문구는 source_id_note에 보존했습니다. 현재 운영 중인 기관 수나 환자 기록을 뜻하지 않습니다.

| 컬럼 | 타입 | 의미 |
| --- | --- | --- |
| source_row_id | INT UNSIGNED | 원본 행 번호, 기본키 |
| district | VARCHAR(60) | 서울 자치구, NULL 불가 |
| facility_type | VARCHAR(50) | 기관 종류, NULL 불가 |
| facility_id | VARCHAR(160) | 암호화 기관 ID, 원본 안내 문구가 있으면 NULL |
| displayed_specialty | VARCHAR(100) | 신고된 표시과목, NULL 허용 |

MySQL에 접속한 뒤 아래를 실행합니다.

```sql
USE health_study;
SHOW COLUMNS FROM facilities;
```

## 공통 입력 예시 (가상 데이터)

| source_row_id | district | facility_type | facility_id | displayed_specialty |
| --- | --- | --- | --- | --- |
| 1 | A구 | 의원 | F001 | 소아청소년과 |
| 2 | A구 | 의원 | NULL | 내과 |
| 3 | A구 | 약국 | F003 | 해당사항없음 |
| 4 | B구 | 의원 | F004 | 내과 |
| 5 | B구 | 치과의원 | F005 | 치과 |

## 문제 1 — 구별 의원 기록 수

기관 종류가 정확히 의원인 행만 구별로 셉니다. ID가 NULL인 의원의 기록도 포함합니다. 의원이 있는 구당 한 행을 출력하고, 의원 수 내림차순 → 구 이름 오름차순으로 정렬합니다.

### 예상 출력 (가상 데이터)

| district | clinic_count |
| --- | --- |
| A구 | 2 |
| B구 | 1 |

### 최종 기록 SQL

```sql
SELECT district, COUNT(*) AS clinic_count
FROM facilities
WHERE facility_type = '의원'
GROUP BY district
ORDER BY clinic_count DESC, district ASC;
```

### 실제 결과 (25행)

사용자 제출 결과와 별도 재실행을 대조했습니다.

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

### 계산과 검증

COUNT(*)는 ID가 NULL이어도 행을 셉니다. 실제 25개 구에서 의원 기록 합계는 10,477건이었습니다.

## 문제 2 — 구별 기관 ID가 없는 기록과 비율

데이터 관리 담당자가 우선 확인할 구를 고를 수 있도록, 모든 기관 종류를 포함해 구별 전체 기록 수, ID가 없는 기록 수, 누락 비율을 출력합니다. 누락이 0인 구도 남깁니다. 비율은 누락 수 ÷ 전체 기록 수 × 100을 소수 둘째 자리로 표시합니다. 누락 수 내림차순 → 구 이름 오름차순으로 정렬합니다.

### 예상 출력 (가상 데이터)

| district | total_record_count | missing_id_count | missing_id_rate |
| --- | --- | --- | --- |
| A구 | 3 | 1 | 33.33 |
| B구 | 2 | 0 | 0.00 |

### 최종 기록 SQL

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

### 실제 결과 (25행)

2번은 사용자 터미널 출력이 공유되지 않아, 아래 표는 로컬 MySQL에서 별도로 실행해 확인한 결과입니다.

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

### 계산과 검증

CASE WHEN은 참·거짓을 판정하는 조건을 받을 수 있으므로, facility_id IS NULL을 넣어 ID가 없는 행을 표시합니다. 조건이 참이면 1, ELSE를 생략한 경우 그 외에는 NULL이 됩니다. COUNT는 NULL을 건너뛰므로 1이 붙은 행만 셉니다. ELSE 0을 추가하면 COUNT가 0도 세므로 결과가 달라집니다. WHERE로 ID가 없는 행만 남기면 전체 기록 수와 누락 0건인 구를 잃습니다. 구별 누락 수를 더하면 165건입니다.

## 문제 3 — 전체 의원 중 소아청소년과 표시과목 비율

추가 검토가 필요한 구를 찾기 위해, 의원 기록만 사용해 구별 전체 의원 수와 표시과목이 정확히 소아청소년과인 의원 수를 비교합니다. 소아청소년과가 0건인 구도 의원 기록이 있으면 남깁니다. 비율은 소아청소년과 의원 수 ÷ 전체 의원 수 × 100을 소수 둘째 자리로 표시합니다. 소아청소년과 의원 수 오름차순 → 구 이름 오름차순입니다.

### 예상 출력 (가상 데이터)

| district | clinic_count | pediatric_clinic_count | pediatric_clinic_rate |
| --- | --- | --- | --- |
| B구 | 1 | 0 | 0.00 |
| A구 | 2 | 1 | 50.00 |

### 최종 기록 SQL

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

### 실제 결과 (25행)

사용자 제출 결과와 별도 재실행을 대조했습니다.

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

### 계산과 검증

분모는 WHERE facility_type = '의원'을 통과한 모든 의원 기록입니다. 분자는 그 안에서 CASE WHEN으로 세는 소아청소년과 표시과목 기록입니다. 표시과목을 WHERE에 넣으면 다른 의원이 분모에서 빠집니다. 25개 구의 분모는 1번과 모두 일치합니다. 이 비율은 신고된 표시과목 기준이며 실제 진료 가능 여부나 의료 접근성을 뜻하지 않습니다.

## 이해 점검·복습

집계 전에 어떤 행이 전체 대상인지 정하고, 그 안에서 조건에 맞는 행만 따로 셉니다. 1번과 3번의 구별 의원 수가 같고, 2번의 전체 행·누락 행 합계가 원본 요약과 같은지 확인합니다.
