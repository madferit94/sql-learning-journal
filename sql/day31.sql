-- Day31: three healthcare data exercises.
USE health_study;

-- Question 1
SELECT district, COUNT(*) AS clinic_count
FROM facilities
WHERE facility_type = '의원'
GROUP BY district
ORDER BY clinic_count DESC, district ASC;

-- Question 2
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

-- Question 3
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
