# 데이터·스키마 안내

[English](data.en.md) · [처음으로](../README.ko.md)

| 데이터 | 일차 | 출처와 한계 |
| --- | --- | --- |
| European Soccer Database | 1–3, 7–8 | 노션에 Hugo Mathien·Kaggle로 기록되어 있습니다. Day1–3은 `Match`·`date`, Day7–8은 로컬 `matches`·`match_date` 및 `league`·`team`을 사용합니다. 가져오기·이름 변경 절차는 포함되어 있지 않습니다. |
| Brazilian E-Commerce / Olist | 4–5, 9–11 | 노션에 Kaggle Olist 데이터로 기록되어 있습니다. 로컬 테이블은 `orders`·`customers`입니다. `customer_id`는 주문 연결 키, `customer_unique_id`는 주문을 넘어 고객을 식별하는 값입니다. |
| 거래 연습 테이블 | 6 | `finance.bank_transactions`. 기록만으로 원제공자 URL과 재배포 조건을 확인할 수 없습니다. 근무 회사나 은행 내부 자료라는 의미가 아닙니다. |

원본 데이터와 DB 덤프는 재배포하지 않습니다. 거래 기록에는 1,048,567행, 2016-08-01~2016-10-21로 적혀 있지만 이번에 다시 검증한 값은 아닙니다. 공개본의 고객 ID는 `CUSTOMER_001` 형식으로 일관되게 가명 처리했습니다.

실행하려면 적절한 경로로 데이터를 구하고 실제 스키마에 맞춰 테이블·컬럼명을 확인해야 합니다. 행 수, 키 중복, 결측치, JOIN 미매칭, 수집 범위를 점검하세요. 기록된 결과만으로는 정확한 재현에 필요한 가져오기 절차와 제약조건을 모두 확인할 수 없습니다.

## 추가 데이터와 로컬 스키마 (2026-10-16)

- Day12~13은 `finance.bank_transactions`를 사용하며 한 행은 거래 한 건입니다. 공개 추가본의 고객 ID는 `FIN_CUSTOMER_001` 형식으로 두 날짜 안에서 일관되게 가명 처리했습니다. 기존 Day06과는 별도 가명 범위이며 원본 금융 기록은 배포하지 않습니다.
- Day14~15는 [바쿠 프로젝트 고정 스냅샷](https://github.com/madferit94/all-sports-analytics/tree/c1e22c8f1d0f14192f92159d59b7b8f12a307ef5/f1/baku-2026)을 사용했습니다. 실시간 OpenF1 조회나 경기 사실의 독립 검증을 뜻하지 않습니다. laps는 983행, 시간 기록 976행·NULL 7행, drivers는 22행입니다. 세션과 드라이버 번호로 연결합니다. 타이어 구간은 드라이버만으로 연결하지 않습니다. 전체 랩 평균이나 109/110초 기준은 실력 비교를 통제한 지표가 아닙니다.
- Day16은 [UCI Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail), Daqing Chen (2015), DOI 10.24432/C5BW33, CC BY 4.0입니다. 원본 상품 항목 541,909행, 고유 주문번호 25,900개입니다. sales_items는 양수 수량·단가 및 비C주문번호의 530,104행을 보여 주며 원본 중복은 남아 있습니다. 단가는 GBP입니다. 국가별 분석에는 고객 NULL을 포함하고 고객별 분석에서는 제외합니다.
- invoice_headers는 주문번호·일시·고객·국가 조합을 나눈 학습용 표로 25,943행입니다. 43개 주문번호에 여러 정보 조합이 있어 헤더 행 수를 고유 주문 수라고 부르지 않습니다. invoice_header_id로 연결하며 주문번호만으로 연결하면 행이 늘어날 수 있습니다. 원본 컬럼은 invoice_items에 보존했습니다.

스키마만 제공하는 파일: [F1](../sql/schema-f1.sql), [Retail](../sql/schema-retail.sql). 원본 데이터·자동 로더는 포함하지 않습니다. XLSX와 DB의 전체 원본 필드를 선언한 타입 변환에 맞춰 대조했으며, 이는 원본 업무 기록 자체의 정확성 보증이 아닙니다. 숫자형 설명 셀은 문자열로 보존했습니다. 연습 금액을 확정 매출로 해석하려면 중복·취소·결측 처리 기준이 필요합니다.

## Day18–21 추가: 금융·CTE·다중 경기 F1

Day18·19는 bank_transactions를 사용합니다. 금융 고객 ID는 기존 Day12·13과 일관된 FIN_CUSTOMER 가명으로 표시하고 필요한 가명을 추가했습니다. 통화는 확정하지 않습니다. 원본·대응표는 공개하지 않습니다.

Day20은 바쿠 단일 세션 11377 기준입니다. 40랩 조건은 공식·통계적 기준이 아닌 학습용 선정 규칙입니다. Day14·15에도 전체 기록 수·팀 합계 기록 수·특정 시간 미만 기록 수의 서로 다른 조건을 구분한 설명을 보충했습니다.

Day21은 오스틴(11396)까지 18개 본 레이스를 사용합니다. 취소된 두 세션·스프린트·예선·연습은 제외했습니다. 적재 기록은 sessions 18행, drivers 396행, laps 20811행, stints 1119행, race_results 396행입니다. 기존 바쿠 데이터 보존, 원본과 DB 모든 행·셀 대조, 드라이버 미연결 0건을 준비 보고서에서 확인했습니다. 이번 게시를 위해 문제 SQL을 다시 실행한 것은 아닙니다.

최종 position·completed_laps·points 396행은 [F1 공식 결과](https://www.formula1.com/en/results/2026/races)와 대조했습니다. 나머지 시간 필드는 비공식 [OpenF1](https://openf1.org/docs/) 자료입니다. status는 DSQ/DNS/DNF 플래그로 만든 파생 컬럼이며 official_position_label·official_time_or_retired에 공식 표시값을 보존합니다.

원본 주의점은 랩타임 NULL 118행, 시작·종료 범위가 뒤집힌 타이어 구간 6행, 세션 11731의 서킷·위치 메타데이터 불일치입니다. 원본 위치는 Kuala Lumpur이지만 국가·공식 대회명은 Bahrain입니다. 원본은 유지하고 grand_prix_name에 공식 이름을 별도로 저장했습니다. 해당 위치·시차를 검증된 지리 정보로 쓰거나 잘못된 구간을 정상 랩 범위로 사용하지 않습니다.

확장 후 예전 바쿠 쿼리에 경기 조건이 없으면 여러 경기가 합쳐집니다. 경기별 통계는 세션 필터나 session_key 그룹화·분할을 명시합니다. 서킷이 다른 평균 랩타임을 그대로 실력 순위로 비교하지 않습니다. 본 레이스 점수에는 스프린트가 없고 RANK는 공식 동점 처리 규칙과 다릅니다.


## Day22: 멕시코 추가와 이커머스 순위

멕시코 본 레이스 11404 추가 후 현재 스냅샷은 sessions 19행, drivers 418행, laps 22171행, stints 1199행, race_results 418행입니다. 추가분은 경기 1·드라이버 참가 22·랩 1360·타이어 구간 80·결과 22행입니다. 기존 18경기의 모든 행을 보존했고 공식 순위·완료 랩·포인트 66개 값의 차이는 0건입니다. 신규 랩타임 NULL 5행으로 전체 123행이며 기존의 잘못된 타이어 구간 6행은 원본 상태로 보존했습니다. 출처는 [OpenF1](https://openf1.org/docs/)과 [F1 멕시코 공식 결과](https://www.formula1.com/en/results/2026/races/1298/mexico/race-result)입니다.

이전 Day는 당시 경기 범위를 유지합니다. 이번 [전체 재검증](audit.ko.md)은 Olist 백업 격리 복원·테이블명 대응·F1 범위 제한 뷰를 사용했습니다. 과거 게시 당시 미실행 설명과 이번 재검증을 구분하며, 원래 실행 결과와 시간은 보존합니다.


## Day23: music_study

kworb 수집 기록(2026-11-05)을 이용한 비틀즈 Spotify 개별 트랙 500행·공식 YouTube 영상 89행입니다. 원본 트랙 ID와 영상 ID는 공개 플랫폼 식별자입니다. 두 플랫폼은 개별 트랙·영상 단위로 분석했고 곡·버전 합산과 플랫폼 간 연결은 하지 않았습니다. Hot100은 이번 세션에 사용하지 않았습니다. 수집 기록의 날짜와 ‘전일’ 기준을 현재 실시간 수치로 해석하지 않습니다.

beatles_spotify_tracks: row_id INT PK, track_id VARCHAR(22), title VARCHAR(255), streams BIGINT (모두 NOT NULL). beatles_youtube_videos: video_id VARCHAR(11) PK, title VARCHAR(255), views BIGINT (NOT NULL), views_yesterday BIGINT (NULL 허용). 현재 두 조회수의 실제 NULL은0건입니다. DB의 utf8mb4_0900_as_cs는 대소문자·악센트를 구분합니다. 모든 Unicode 문자열 비교가 Python과 같음을 보증하지는 않습니다.

분석용 학습 데이터이며 원본 CSV·적재 스크립트·인증 파일·프로젝트 개인 경로는 공개하지 않습니다. 노션의 첫 소개는 다양한 분야의 실제 데이터에 같은 SQL 원리를 적용하는 방향으로 수정했습니다. 음악 세션은 넘버로그 콘텐츠 기획 질문과 연결한 연습이며 직접적 플랫폼 효과나 인과 분석은 아닙니다.
