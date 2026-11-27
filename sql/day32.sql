-- Day32: general-hospital records, citywide share, and cumulative share.
USE health_study;

-- Question 1
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

-- Question 2
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

-- Question 3
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
