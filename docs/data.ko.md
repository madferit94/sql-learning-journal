# 데이터·스키마 안내

[English](data.en.md) · [처음으로](../README.ko.md)

| 데이터 | 일차 | 출처와 한계 |
| --- | --- | --- |
| European Soccer Database | 1–3, 7–8 | 노션에 Hugo Mathien·Kaggle로 기록되어 있습니다. Day1–3은 `Match`·`date`, Day7–8은 로컬 `matches`·`match_date` 및 `league`·`team`을 사용합니다. 가져오기·이름 변경 절차는 포함되어 있지 않습니다. |
| Brazilian E-Commerce / Olist | 4–5, 9–11 | 노션에 Kaggle Olist 데이터로 기록되어 있습니다. 로컬 테이블은 `orders`·`customers`입니다. `customer_id`는 주문 연결 키, `customer_unique_id`는 주문을 넘어 고객을 식별하는 값입니다. |
| 거래 연습 테이블 | 6 | `finance.bank_transactions`. 기록만으로 원제공자 URL과 재배포 조건을 확인할 수 없습니다. 근무 회사나 은행 내부 자료라는 의미가 아닙니다. |

원본 데이터와 DB 덤프는 재배포하지 않습니다. 거래 기록에는 1,048,567행, 2016-08-01~2016-10-21로 적혀 있지만 이번에 다시 검증한 값은 아닙니다. 공개본의 고객 ID는 `CUSTOMER_001` 형식으로 일관되게 가명 처리했습니다.

실행하려면 적절한 경로로 데이터를 구하고 실제 스키마에 맞춰 테이블·컬럼명을 확인해야 합니다. 행 수, 키 중복, 결측치, JOIN 미매칭, 수집 범위를 점검하세요. 기록된 결과만으로는 정확한 재현에 필요한 가져오기 절차와 제약조건을 모두 확인할 수 없습니다.
