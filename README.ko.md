# SQL 학습 기록

한국어 | [English](README.md)

데이터 분석가를 준비하며 작성한 SQL TIL(Today I Learned, 오늘 배운 내용)입니다. 축구·이커머스·거래 데이터로 월별 주문 지표, 재구매 고객, 조건부 집계 같은 질문을 쿼리로 바꾸는 연습을 기록했습니다.

분석 질문을 쿼리로 옮기고, 한 행의 의미를 이해하며, 오류를 수정하고 결과를 점검하는 과정을 기록합니다. 독립적인 숙련도를 증명하거나 실무 분석 프로젝트의 완성을 주장하는 저장소는 아닙니다.

## 학습 목차

| 일차 | 주제 | 한글 | 영어 | SQL |
| --- | --- | --- | --- | --- |
| 01 | 기본 조회·필터링·집계 | [한글](til/ko/day01.md) | [English](til/en/day01.md) | [쿼리](sql/day01.sql) |
| 02 | 집계와 행 조건 | [한글](til/ko/day02.md) | [English](til/en/day02.md) | [쿼리](sql/day02.sql) |
| 03 | WHERE와 HAVING | [한글](til/ko/day03.md) | [English](til/en/day03.md) | [쿼리](sql/day03.sql) |
| 04 | Olist 주문 집계 | [한글](til/ko/day04.md) | [English](til/en/day04.md) | [쿼리](sql/day04.sql) |
| 05 | 고객 식별자와 JOIN | [한글](til/ko/day05.md) | [English](til/en/day05.md) | [쿼리](sql/day05.sql) |
| 06 | 거래 집계와 CASE WHEN | [한글](til/ko/day06.md) | [English](til/en/day06.md) | [쿼리](sql/day06.sql) |
| 07 | 축구 JOIN과 팀 별칭 | [한글](til/ko/day07.md) | [English](til/en/day07.md) | [쿼리](sql/day07.sql) |
| 08 | 축구 결과 분류와 집계 | [한글](til/ko/day08.md) | [English](til/en/day08.md) | [쿼리](sql/day08.sql) |
| 09 | Olist JOIN과 2단계 집계 | [한글](til/ko/day09.md) | [English](til/en/day09.md) | [쿼리](sql/day09.sql) |
| 10 | 월별 집계와 재구매 고객 | [한글](til/ko/day10.md) | [English](til/en/day10.md) | [쿼리](sql/day10.sql) |
| 11 | 조건부 집계와 서브쿼리 복습 | [한글](til/ko/day11.md) | [English](til/en/day11.md) | [쿼리](sql/day11.sql) |
| 12 | Finance 고객 집계·조건부 집계·서브쿼리 (2026-10-10) | [한글](til/ko/day12.md) | [English](til/en/day12.md) | [쿼리](sql/day12.sql) |
| 13 | Finance 조건부 집계·비율·서브쿼리 (2026-10-11) | [한글](til/ko/day13.md) | [English](til/en/day13.md) | [쿼리](sql/day13.sql) |
| 14 | Baku F1 집계·JOIN·조건부 COUNT·서브쿼리 (2026-10-12) | [한글](til/ko/day14.md) | [English](til/en/day14.md) | [쿼리](sql/day14.sql) |
| 15 | Baku F1 2일차·조건부 집계·팀 통계·서브쿼리 (2026-10-13) | [한글](til/ko/day15.md) | [English](til/en/day15.md) | [쿼리](sql/day15.sql) |
| 16 | Online Retail 국가·고객 집계·JOIN·서브쿼리 (2026-10-16) | [한글](til/ko/day16.md) | [English](til/en/day16.md) | [쿼리](sql/day16.sql) |
| 17 | Online Retail 월별 집계·날짜 필터·서브쿼리 | [한글](til/ko/day17.md) | [English](til/en/day17.md) | [쿼리](sql/day17.sql) |
| 18 | Finance 월별 집계·거래일 수·서브쿼리 | [한글](til/ko/day18.md) | [English](til/en/day18.md) | [쿼리](sql/day18.sql) |
| 19 | Finance 집계 복습·CTE 기초 | [한글](til/ko/day19.md) | [English](til/en/day19.md) | [쿼리](sql/day19.sql) |
| 20 | F1 JOIN·CTE·윈도우 함수 기초 | [한글](til/ko/day20.md) | [English](til/en/day20.md) | [쿼리](sql/day20.sql) |
| 21 | F1 오스틴 결과·다중 경기 집계·CTE·윈도우 함수 | [한글](til/ko/day21.md) | [English](til/en/day21.md) | [쿼리](sql/day21.sql) |

## 학습 범위

- SELECT·WHERE·ORDER BY·GROUP BY·HAVING·JOIN·CASE WHEN·DISTINCT·날짜 함수
- 고객·드라이버 단위 중간 결과를 만드는 서브쿼리와 CTE
- RANK·PARTITION BY를 이용한 전체 순위와 팀 내 순위
- 한 행의 의미, JOIN 키, NULL 처리, 분모, 이적 기록과 지표 해석

현재 21개 세션·최종 기록 SQL 110개입니다. 학습 기록이며 운영 서비스나 실무 경력으로 소개하지 않습니다. 설명과 한영 문서 편집에 AI를 활용했습니다.

## 데이터와 실행 결과

축구·Olist·금융 거래·UCI Online Retail·F1 데이터를 사용합니다. [데이터와 스키마 안내](docs/data.ko.md)를 확인하세요. 원본 데이터, DB 덤프, 인증정보, 개인 경로와 비공개 Notion 원문은 저장소에 올리지 않습니다.

결과표는 학습 중 실행 기록이며 이번 게시를 위해 SQL을 다시 실행한 결과가 아닙니다. Day19 1번에는 추가로 공유된 3행 결과와 당시 DB 대조 기록을 반영했습니다.

F1 Day14·15·20은 바쿠 단일 세션 기준이고 Day21은 오스틴까지 18개 본 레이스를 사용합니다. DB 확장 후 예전 쿼리를 실행하면 여러 경기가 섞일 수 있으므로 경기 범위를 명시해야 합니다. 본 레이스 포인트 합계·RANK 공동 순위는 공식 챔피언십 순위와 다릅니다. 랩타임 평균과 기록 수 기준도 공식 성적·실력 순위로 해석하지 않습니다.

## 활용 방법

1. 문제와 테이블 설명을 보고 결과 한 행의 의미를 먼저 정합니다.
2. 직접 작성한 뒤 연결 키·조건·집계 단위·분모를 비교합니다.
3. 실행 결과와 지표의 의미를 확인합니다.
4. 조건을 바꾼 문제를 이전 답 없이 다시 작성합니다.

한국어판은 Notion 상세 기록을 따르고, 영어판은 같은 문제·최종 SQL·결과값·해석 한계를 정리한 편집 번역입니다. [편집 및 검증 안내](docs/editorial.ko.md)에서 게시 검증 범위를 확인할 수 있습니다.

출처: [Notion SQL TIL](https://www.notion.so/7b736fd8bbd949ca93f84cdc66987ace). 수동 동기화 기준: 2026-10-27. 자동 동기화 기능은 아닙니다.
