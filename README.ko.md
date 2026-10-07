# SQL 학습 기록

한국어 | [English](README.md)

데이터 분석가를 준비하며 작성한 **Day1~Day11, 총 60문제**의 SQL TIL(Today I Learned, 오늘 배운 내용)입니다. 축구·이커머스·거래 데이터를 예제로 사용했습니다.

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

## 현재 학습 범위

- 연습한 내용: SELECT, WHERE, ORDER BY, LIMIT, GROUP BY, HAVING, JOIN, CASE WHEN, DISTINCT, 날짜 함수, 집계 서브쿼리.
- 이해를 보완하는 내용: 조건부 집계, 2단계 집계, 고객 수의 분모, 빈 화면에서 쿼리 작성하기.
- 다음 목표: CTE, 윈도우 함수. 아직 학습 완료 항목으로 표시하지 않았습니다.

설명·오류 수정과 이번 한영 문서 정리에 AI의 도움을 받았습니다. 실패한 시도와 해결하지 못한 부분을 남겼으며, AI의 도움을 받은 작업을 혼자 완성했다고 표시하지 않습니다.

## 데이터와 실행 범위

노션 기록상 환경은 MySQL 8.4입니다. European Soccer Database, Olist, 거래 연습 테이블을 사용했습니다. 원본 데이터·접속 정보·로컬 가져오기 설정은 포함하지 않았습니다. 날짜별 스키마가 달라 그대로 한 번에 실행하는 프로젝트는 아닙니다. 실행 전 [데이터·스키마 안내](docs/data.ko.md)를 확인해 주세요.

표와 수치는 **당시 노션에 기록된 결과**이며, 이번 게시 과정에서 SQL을 다시 실행하거나 결과를 독립 검증하지 않았습니다. Day11 문제 3은 ERROR 1064 기록과 미해결 상태를 유지했습니다. 자세한 내용은 [편집·검증 안내](docs/editorial.ko.md)에 있습니다.

## 복습 방법

1. 정답을 보기 전에 문제를 읽고 결과의 한 행이 무엇을 의미하는지 적습니다.
2. 직접 쿼리를 작성한 뒤 기존 시도와 설명을 비교합니다.
3. 키·행 수·필터·그룹·분모를 점검합니다.
4. 틀린 이유를 적고 조건을 바꾼 문제를 답 없이 다시 풉니다.

한글판은 상세 기록의 서식을 정리한 공개본입니다. 영문판은 모든 문제의 질문·학습 포인트·주요 시행착오·최종 기록 쿼리·결과 발췌를 번역한 학습판이며, 반복 설명은 줄였습니다.

원출처: [Notion SQL TIL](https://www.notion.so/7b736fd8bbd949ca93f84cdc66987ace) (접근 권한이 필요할 수 있습니다). 게시 기준일: 2026-10-08. 자동 동기화가 아닌 수동 스냅샷입니다.
