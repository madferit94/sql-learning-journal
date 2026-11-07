# Day 23 — 음악 트랙·영상 순위·CTE·CAST·조건부 집계

[English](../en/day23.md) · [목차](../../README.ko.md)

<details>
<summary>🎵 Day23 — 음악 트랙·영상 순위·CTE·CAST·조건부 집계</summary>

# SQL 학습 기록 — Day 23

## 학습 개요

<b>환경:</b> MySQL 8.4 / music_study
<b>범위:</b> Spotify 개별 트랙 순위·YouTube 누적/전일 순위·CTE·RANK·순위 차이·CAST·조건부 COUNT·비율
<b>데이터:</b> kworb 수집 스냅샷(수집 기록 2026-11-05), Spotify 트랙 500행·공식 YouTube 영상 89행. Hot100은 이번 세션에 사용하지 않았습니다.

### 음악 데이터를 선택한 이유

넘버로그 뮤직의 비틀즈 콘텐츠 기획에서 나온 질문을 직접 SQL로 확인하기 위해 음악 데이터를 선택했습니다. 누적 재생·조회 규모와 특정 하루의 조회 흐름에서 콘텐츠의 상대적 위치가 어떻게 달라지는지 살펴보는 것이 출발점입니다.

기존에 연습한 CTE·RANK·조건부 집계를 음악 데이터에 적용하고, 트랙·영상의 집계 단위와 분모를 스스로 판단하는 연습입니다. 관심 분야의 실제 콘텐츠 기획과 SQL 학습을 연결하되, 영상 제작과 SQL 분석의 완료 여부는 구분합니다.

이번 세션에서는 플랫폼별 개별 트랙·영상의 순위와 YouTube의 누적·전일 순위 차이 및 조건 충족 비율을 확인했습니다. 동일 음원을 연결한 플랫폼 간 직접 비교나 순위 차이의 원인 분석은 후속 과제입니다.

순위의 비교 대상과 최종 출력 대상, 순위 차이와 조건 충족 행 수를 구분합니다. 리마스터·믹스·라이브는 개별 트랙/영상으로 유지하며 곡별 합산은 하지 않았습니다.

### 접속

일반 터미널에서 실행합니다.

```bash
mysql -u root -p
```

mysql> 화면에서 실행합니다.

```sql
USE music_study;
```

<details>
<summary>🏁 문제 1 — Spotify 누적 재생 수 상위 10개 트랙</summary>

## 문제 1. Spotify 누적 재생 수 상위 10개 트랙

### 테이블과 한 행의 의미

beatles_spotify_tracks의 한 행은 Spotify 개별 트랙 하나입니다. 같은 곡의 리마스터·믹스·라이브는 별도 트랙일 수 있습니다. 현재 500행이고 track_id는 이 스냅샷에서 모두 다릅니다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| row_id | INT | 행 식별자·기본키, NULL 불가 |
| track_id | VARCHAR(22) | Spotify 트랙 ID, NULL 불가 |
| title | VARCHAR(255) | 트랙 제목, NULL 불가 |
| streams | BIGINT | 누적 재생 횟수, NULL 불가 |

### 문제와 조건

개별 트랙의 누적 재생 수와 순위를 조회합니다.

- beatles_spotify_tracks만 사용하고 곡·버전별 합산을 하지 않습니다.
- 전체 500개 트랙을 기준으로 RANK를 계산하며 재생 수가 많을수록 높은 순위입니다.
- 재생 수 동점은 공동 순위이며 다음 순위는 건너뜁니다.
- 최종 재생 수 내림차순, 동점이면 row_id 오름차순입니다.
- 정확히 10행만 출력하며 경계의 동점 트랙을 추가로 포함하지 않습니다.
- 정수 재생 수를 그대로 출력합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| stream_rank | 전체 트랙의 누적 재생 수 순위 |
| track_id | 트랙 ID |
| title | 트랙 제목 |
| streams | 누적 재생 수 |

결과 한 행은 개별 트랙 하나입니다.

### 가상 예시와 해설

가상 트랙 A가 900000회, B·C가 각각 800000회라면 순위는 1·2·2이고 다음 낮은 트랙은 4위입니다.

### 최종 쿼리

```sql
WITH stream_rank AS (
    SELECT row_id, track_id, title, streams
    FROM beatles_spotify_tracks
)
SELECT
    RANK() OVER (ORDER BY streams DESC) AS stream_rank,
    track_id, title, streams
FROM stream_rank
ORDER BY streams DESC, row_id ASC
LIMIT 10;
```

### 실제 실행 결과

| stream_rank | track_id | title | streams |
| --- | --- | --- | --- |
| 1 | 5bIEpKwEFgJzB7U3gFaeKm | Here Comes The Sun - Remastered 2009 | 1954864380 |
| 2 | 71JkCL6msHDScuCKaJXFXP | Come Together - Remastered 2009 | 1012937040 |
| 3 | 7iN1s7xHE4ifF5povM6A48 | Let It Be - Remastered 2009 | 1008231850 |
| 4 | 3BQHpFgAp4l80e1XslIjNI | Yesterday - Remastered 2009 | 901423229 |
| 5 | 3m7V717IKZqZLW5qUIOxdD | Hey Jude - Remastered 2009 | 802071274 |
| 6 | 5jgFfDIR6FR0gvlA56Nakr | Blackbird - Remastered 2009 | 735732770 |
| 7 | 5ZBeML7Lf3FMEVviTyvi8l | Twist And Shout - Remastered 2009 | 715536569 |
| 8 | 3KfbEIOC7YIv90FIfNSZpo | In My Life - Remastered 2009 | 665769258 |
| 9 | 5Qe7NHxeLAn8KoLTNLSdwe | I Want To Hold Your Hand - Remastered 2009 | 552949516 |
| 10 | 4ALYlZ5CAqScpssy9pFfDx | Something - Remastered 2009 | 551434621 |

사용자 실행 결과: 10 rows in set (0.03 sec). 위 시간은 사용자 터미널 기록입니다. 업로드 준비 시 동일 DB에서 최종 SQL을 읽기 전용으로 대조해 행 수와 주요 결과 일치를 확인했으며, 대조 실행 시간을 사용자 시간으로 대체하지 않았습니다.

### 오류 수정·핵심 개념과 해석

CTE는 필수가 아니지만 제출 구조도 올바릅니다. CTE와 출력 컬럼이 모두 stream_rank여도 문법상 문제는 없습니다. RANK에는 streams만 넣고, row_id는 최종 표시 순서에만 사용해 공동 순위를 보존합니다. Here Comes The Sun - Remastered 2009는 수집된 개별 트랙 중 1위·1954864380회입니다. 곡 전체의 모든 버전을 합친 재생 수라는 뜻은 아닙니다.
</details>

<details>
<summary>🏁 문제 2 — 공식 영상의 누적·전일 조회수 순위</summary>

## 문제 2. 공식 영상의 누적·전일 조회수 순위

### 테이블과 한 행의 의미

beatles_youtube_videos의 한 행은 공식 YouTube 영상 하나입니다. 같은 곡의 서로 다른 영상도 개별 행입니다. 현재 89행입니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| video_id | VARCHAR(11) | 영상 ID·기본키, NULL 불가 |
| title | VARCHAR(255) | 영상 제목, NULL 불가 |
| views | BIGINT | 누적 조회 횟수, NULL 불가 |
| views_yesterday | BIGINT | 수집 자료의 전일 조회 횟수, 스키마상 NULL 허용 |

현재 스냅샷에서 views·views_yesterday의 실제 NULL은 모두 0건입니다. 전일은 오늘이 아닌 수집 자료의 기준일에 대응합니다. 조회수는 고유 시청자 수와 구분합니다.

### 문제와 조건

전일 조회수가 많은 영상 10개를 조회하고 누적·전일 순위를 함께 표시합니다.

- beatles_youtube_videos만 사용하고 같은 곡의 여러 영상을 합산하지 않습니다.
- 두 순위 모두 전체 89개 영상을 비교 대상으로 합니다.
- 누적·전일 조회수 각각 내림차순의 RANK를 사용하며 동점은 공동 순위·다음 순위는 건너뜁니다.
- 최종 전일 조회수 내림차순, 동점이면 video_id 오름차순입니다.
- 정확히 10행만 출력합니다. 정수 조회수를 그대로 표시합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| total_rank | 전체 영상 중 누적 조회수 순위 |
| daily_rank | 전체 영상 중 전일 조회수 순위 |
| video_id | 영상 ID |
| title | 영상 제목 |
| views | 누적 조회수 |
| views_yesterday | 전일 조회수 |

결과 한 행은 개별 영상 하나입니다.

### 가상 예시와 해설

가상 영상 A가 누적 3위·전일 1위, B가 누적 1위·전일 2위일 수 있습니다. 서로 다른 지표의 순위를 함께 봅니다.

### 최종 쿼리

```sql
WITH beatles_rank AS (
    SELECT
        RANK() OVER (ORDER BY views DESC) AS total_rank,
        video_id, title, views, views_yesterday
    FROM beatles_youtube_videos
)
SELECT
    total_rank,
    RANK() OVER (ORDER BY views_yesterday DESC) AS daily_rank,
    video_id, title, views, views_yesterday
FROM beatles_rank
ORDER BY views_yesterday DESC, video_id ASC
LIMIT 10;
```

### 실제 실행 결과

| total_rank | daily_rank | video_id | title | views | views_yesterday |
| --- | --- | --- | --- | --- | --- |
| 11 | 1 | CGj85pVzRJs | The Beatles - The Beatles - Let It Be (Official Music Video) \[Remastered 2015\] | 135114357 | 168360 |
| 1 | 2 | NCtzkaL2t_Y | The Beatles - The Beatles - Don't Let Me Down (Live Performance) \[Mono / 2009 Remaster\] | 585732182 | 121536 |
| 3 | 3 | KQetemT1sWc | The Beatles - Here Comes The Sun (2019 Mix) | 215127242 | 79200 |
| 2 | 4 | A_MjCqQoLLA | The Beatles - The Beatles - Hey Jude (Official Music Video) \[Remastered 2015\] | 459320807 | 64944 |
| 19 | 5 | Opxhh9Oh3rg | The Beatles - The Beatles - Now And Then (Official Music Video) | 87609220 | 41616 |
| 8 | 6 | UelDrZ1aFeY | The Beatles - Something | 156849566 | 39480 |
| 5 | 7 | 2Q_ZzBGPdqE | The Beatles - Help! | 179934235 | 39264 |
| 14 | 8 | wXTJBr9tt8Q | The Beatles - Yesterday (Live With Spoken Word Intro, New York) \[Remastered 2015\] | 115386665 | 36840 |
| 7 | 9 | 45cYwDMibGo | The Beatles - Come Together | 165382643 | 34416 |
| 12 | 10 | m2uTFF_3MaA | The Beatles - Yellow Submarine | 127202300 | 25632 |

사용자 실행 결과: 10 rows in set (0.06 sec). 위 시간은 사용자 터미널 기록입니다. 업로드 준비 시 동일 DB에서 최종 SQL을 읽기 전용으로 대조해 행 수와 주요 결과 일치를 확인했으며, 대조 실행 시간을 사용자 시간으로 대체하지 않았습니다.

### 오류 수정·핵심 개념과 해석

누적 순위는 CTE 안, 전일 순위는 바깥에서 계산해도 중간 필터 없이 전체 89행을 유지하므로 올바릅니다. Let It Be는 누적 11위·전일 1위, Don't Let Me Down은 누적 1위·전일 2위입니다. 누적 규모와 전일 흐름의 상대적 위치가 다릅니다.
</details>

<details>
<summary>🧩 문제 3 — Here Comes The Sun의 전체 영상 중 순위</summary>

## 문제 3. Here Comes The Sun의 전체 영상 중 순위

### 테이블과 한 행의 의미

beatles_youtube_videos의 한 행은 공식 YouTube 영상 하나입니다. 같은 곡의 서로 다른 영상도 개별 행입니다. 현재 89행입니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| video_id | VARCHAR(11) | 영상 ID·기본키, NULL 불가 |
| title | VARCHAR(255) | 영상 제목, NULL 불가 |
| views | BIGINT | 누적 조회 횟수, NULL 불가 |
| views_yesterday | BIGINT | 수집 자료의 전일 조회 횟수, 스키마상 NULL 허용 |

현재 스냅샷에서 views·views_yesterday의 실제 NULL은 모두 0건입니다. 전일은 오늘이 아닌 수집 자료의 기준일에 대응합니다. 조회수는 고유 시청자 수와 구분합니다.

### 문제와 조건

Here Comes The Sun (2019 Mix) 영상의 전체 영상 중 두 순위를 조회합니다.

- beatles_youtube_videos만 사용하고 CTE를 활용합니다.
- 누적·전일 순위는 각각 전체 89개 영상과 비교한 RANK입니다. 조회수 내림차순이며 동점은 공동 순위·다음 순위는 건너뜁니다.
- 최종 출력은 video_id = 'KQetemT1sWc' 한 영상만 포함합니다.
- 같은 곡의 다른 영상은 합산하지 않습니다. 조회수는 정수 그대로 표시합니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| total_rank | 전체 영상 중 누적 조회수 순위 |
| daily_rank | 전체 영상 중 전일 조회수 순위 |
| video_id | 영상 ID |
| title | 영상 제목 |
| views | 누적 조회수 |
| views_yesterday | 전일 조회수 |

결과 한 행은 개별 영상 하나입니다.

### 가상 예시와 해설

가상 영상이 누적 7위·전일 4위라면 한 행에 7·4를 표시합니다. 한 행만 보여도 순위 계산의 비교 대상은 전체 영상입니다.

### 최종 쿼리

```sql
WITH beatles_rank AS (
    SELECT
        RANK() OVER (ORDER BY views DESC) AS total_rank,
        RANK() OVER (ORDER BY views_yesterday DESC) AS daily_rank,
        video_id, title, views, views_yesterday
    FROM beatles_youtube_videos
)
SELECT total_rank, daily_rank, video_id, title, views, views_yesterday
FROM beatles_rank
WHERE video_id = 'KQetemT1sWc'
ORDER BY total_rank ASC, video_id ASC;
```

### 실제 실행 결과

| total_rank | daily_rank | video_id | title | views | views_yesterday |
| --- | --- | --- | --- | --- | --- |
| 3 | 3 | KQetemT1sWc | The Beatles - Here Comes The Sun (2019 Mix) | 215127242 | 79200 |

사용자 실행 결과: 1 rows in set (0.07 sec). 위 시간은 사용자 터미널 기록입니다. 업로드 준비 시 동일 DB에서 최종 SQL을 읽기 전용으로 대조해 행 수와 주요 결과 일치를 확인했으며, 대조 실행 시간을 사용자 시간으로 대체하지 않았습니다.

### 오류 수정·핵심 개념과 해석

첫 시도는 누적 순위만 CTE에서 계산하고, 바깥 WHERE로 특정 영상 한 개를 남긴 뒤 전일 RANK를 계산했습니다. 결과가 누적 3위·전일 1위여서 문제 조건에 맞지 않았습니다.

```sql
-- 첫 시도의 핵심 구조: 이 단계의 daily_rank는 남은 한 영상만 비교
SELECT total_rank,
       RANK() OVER (ORDER BY views_yesterday DESC) AS daily_rank
FROM beatles_rank
WHERE video_id = 'KQetemT1sWc';
```

두 순위를 모두 CTE에서 계산하고 바깥에서 영상만 고르는 방식으로 수정했습니다. 최종 결과는 3위·3위입니다. 기본키 필터라 최대 한 행이므로 최종 ORDER BY는 불필요하지만 오답은 아닙니다. LIMIT 없는 최종 제출본을 기록합니다.
</details>

<details>
<summary>🧩 문제 4 — 누적 순위보다 전일 순위가 높은 영상</summary>

## 문제 4. 누적 순위보다 전일 순위가 높은 영상

### 테이블과 한 행의 의미

beatles_youtube_videos의 한 행은 공식 YouTube 영상 하나입니다. 같은 곡의 서로 다른 영상도 개별 행입니다. 현재 89행입니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| video_id | VARCHAR(11) | 영상 ID·기본키, NULL 불가 |
| title | VARCHAR(255) | 영상 제목, NULL 불가 |
| views | BIGINT | 누적 조회 횟수, NULL 불가 |
| views_yesterday | BIGINT | 수집 자료의 전일 조회 횟수, 스키마상 NULL 허용 |

현재 스냅샷에서 views·views_yesterday의 실제 NULL은 모두 0건입니다. 전일은 오늘이 아닌 수집 자료의 기준일에 대응합니다. 조회수는 고유 시청자 수와 구분합니다.

### 문제와 조건

누적 조회수 순위보다 전일 조회수 순위가 10계단 이상 높은 영상을 모두 조회합니다.

- beatles_youtube_videos만 사용하고 CTE를 활용합니다.
- 전체 영상에서 누적·전일 조회수 내림차순 RANK를 각각 계산합니다. 동점은 공동 순위·다음 순위는 건너뜁니다.
- rank_gap = 누적 순위 − 전일 순위입니다. 음수가 될 수 있습니다.
- rank_gap >= 10인 영상을 모두 출력합니다. 10은 행 수 제한이 아닙니다.
- rank_gap 내림차순, 동점이면 video_id 오름차순입니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| video_id | 영상 ID |
| title | 영상 제목 |
| total_rank | 누적 순위 |
| daily_rank | 전일 순위 |
| rank_gap | 누적 순위 − 전일 순위 |

결과 한 행은 개별 영상 하나입니다.

### 가상 예시와 해설

가상 영상 A의 누적 40위 − 전일 8위 = 32이면 포함합니다. 누적 15위 − 전일 12위 = 3이면 제외합니다.

### 최종 쿼리

```sql
WITH beatles_rank AS (
    SELECT
        RANK() OVER (ORDER BY views DESC) AS total_rank,
        RANK() OVER (ORDER BY views_yesterday DESC) AS daily_rank,
        video_id, title, views, views_yesterday
    FROM beatles_youtube_videos
)
SELECT
    video_id, title, total_rank, daily_rank,
    (CAST(total_rank AS SIGNED) - CAST(daily_rank AS SIGNED)) AS rank_gap
FROM beatles_rank
WHERE (CAST(total_rank AS SIGNED) - CAST(daily_rank AS SIGNED)) >= 10
ORDER BY rank_gap DESC, video_id ASC;
```

### 실제 실행 결과

| video_id | title | total_rank | daily_rank | rank_gap |
| --- | --- | --- | --- | --- |
| _HJIndFgLG4 | The Beatles - In My Life - 2026 Mix (Visualiser) | 81 | 16 | 65 |
| Zq0HMLhaQOw | The Beatles - The Beatles - Michelle (Take 1) (Visualiser) | 79 | 44 | 35 |
| Mki34tyoCp0 | The Beatles - All You Need Is Love (Live from Abbey Road Studios, June 25th, 1967) | 56 | 22 | 34 |
| B7VaUSNd8xQ | The Beatles - Two Of Us (Performance from ‘Let It Be’) | 58 | 29 | 29 |
| i74wnIwXBpw | The Beatles - While My Guitar Gently Weeps (Third Version - Take 27 / Visualiser) | 87 | 60 | 27 |
| ja7P5890yIM | The Beatles - I Want To Tell You | 80 | 57 | 23 |
| FusIKjztap8 | The Beatles - Here, There and Everywhere | 33 | 11 | 22 |
| a396v8kuViw | The Beatles - Doctor Robert | 76 | 55 | 21 |
| iL1kUOomzoE | The Beatles - The Beatles - In My Life (Take 1) \[Anthology 2025\] | 77 | 56 | 21 |
| SnYc4mQtbHM | The Beatles - Something (Take 39 / Instrumental / Strings Only / Audio) | 89 | 68 | 21 |
| G2uCNd1AVJo | Today Pepperland Goes Blue! | 83 | 66 | 17 |
| sa3948JzWCc | The Inner Light | 75 | 59 | 16 |
| iCs9goFpiQ0 | The Beatles - Love You To | 69 | 54 | 15 |
| Opxhh9Oh3rg | The Beatles - The Beatles - Now And Then (Official Music Video) | 19 | 5 | 14 |
| NZOBWYHgZjw | The Beatles - She Said She Said | 61 | 48 | 13 |
| gMdcE8jdz70 | The Beatles - Taxman | 48 | 36 | 12 |
| hgJ7dmr_ysU | The Beatles - For No One | 50 | 38 | 12 |
| R9ncBUcInTM | The Beatles - Good Day Sunshine | 62 | 50 | 12 |
| 9g2eU9YGwWQ | The Beatles - And Your Bird Can Sing | 53 | 42 | 11 |
| m4BuziKGMy4 | The Beatles - Tomorrow Never Knows | 54 | 43 | 11 |
| CGj85pVzRJs | The Beatles - The Beatles - Let It Be (Official Music Video) \[Remastered 2015\] | 11 | 1 | 10 |

사용자 실행 결과: 21 rows in set (0.06 sec). 위 시간은 사용자 터미널 기록입니다. 업로드 준비 시 동일 DB에서 최종 SQL을 읽기 전용으로 대조해 행 수와 주요 결과 일치를 확인했으며, 대조 실행 시간을 사용자 시간으로 대체하지 않았습니다.

### 오류 수정·핵심 개념과 해석

CAST는 조회수가 아니라 두 순위에 적용했습니다. 차이가 음수가 될 수 있어 SIGNED로 변환한 뒤 뺍니다. 81 − 16 = 65인 영상이 첫 행입니다. 65는 서로 다른 누적·전일 지표의 순위 차이이며 어제보다 65계단 상승했다는 뜻이 아닙니다. 조건은 누적 상위 10위가 아니라 순위 차이 >= 10입니다.
</details>

<details>
<summary>🧩 문제 5 — 순위 차이가 10 이상인 영상의 비율</summary>

## 문제 5. 순위 차이가 10 이상인 영상의 비율

### 테이블과 한 행의 의미

beatles_youtube_videos의 한 행은 공식 YouTube 영상 하나입니다. 같은 곡의 서로 다른 영상도 개별 행입니다. 현재 89행입니다. 필요한 컬럼만 표시합니다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| video_id | VARCHAR(11) | 영상 ID·기본키, NULL 불가 |
| title | VARCHAR(255) | 영상 제목, NULL 불가 |
| views | BIGINT | 누적 조회 횟수, NULL 불가 |
| views_yesterday | BIGINT | 수집 자료의 전일 조회 횟수, 스키마상 NULL 허용 |

현재 스냅샷에서 views·views_yesterday의 실제 NULL은 모두 0건입니다. 전일은 오늘이 아닌 수집 자료의 기준일에 대응합니다. 조회수는 고유 시청자 수와 구분합니다.

### 문제와 조건

전체 영상 중 누적 순위 − 전일 순위가 10 이상인 영상의 수와 비율을 조회합니다.

- beatles_youtube_videos만 사용하고 CTE를 활용합니다.
- 두 순위는 전체 영상을 비교 대상으로 하는 조회수 내림차순 RANK입니다. 동점은 공동 순위·다음 순위는 건너뜁니다.
- 순위 차이는 누적 순위 − 전일 순위이며 음수가 될 수 있습니다.
- 분자: 순위 차이가 10 이상인 영상 수. 분모: 전체 영상 수.
- 비율은 분자 ÷ 분모 × 100이며 마지막에 소수 둘째 자리까지 반올림합니다.
- 영상 수를 직접 입력하지 말고 데이터에서 계산합니다.
- 최종 결과는 전체를 요약한 한 행입니다. 최종 정렬은 필요하지 않습니다.

### 출력 컬럼

| 컬럼 | 의미 |
| --- | --- |
| total_video_count | 전체 영상 수 |
| high_gap_video_count | 순위 차이 10 이상 영상 수 |
| high_gap_rate | 전체 대비 조건 충족 비율(%) |

결과 한 행은 전체 영상을 요약한 통계입니다.

### 가상 예시와 해설

가상 전체 100개 중 조건 충족이 20개이면 비율은 20 ÷ 100 × 100 = 20.00%입니다. 분모에는 불충족 영상도 포함합니다.

### 최종 쿼리

```sql
WITH beatles_youtube AS (
    SELECT
        RANK() OVER (ORDER BY views DESC) AS total_rank,
        RANK() OVER (ORDER BY views_yesterday DESC) AS daily_rank
    FROM beatles_youtube_videos
)
SELECT
    COUNT(*) AS total_video_count,
    COUNT(
        CASE WHEN CAST(total_rank AS SIGNED) - CAST(daily_rank AS SIGNED) >= 10
             THEN 1 END
    ) AS high_gap_video_count,
    ROUND(
        COUNT(
            CASE WHEN CAST(total_rank AS SIGNED) - CAST(daily_rank AS SIGNED) >= 10
                 THEN 1 END
        ) / COUNT(*) * 100,
        2
    ) AS high_gap_rate
FROM beatles_youtube;
```

### 실제 실행 결과

| total_video_count | high_gap_video_count | high_gap_rate |
| --- | --- | --- |
| 89 | 21 | 23.60 |

사용자 실행 결과: 1 rows in set (0.08 sec). 위 시간은 사용자 터미널 기록입니다. 업로드 준비 시 동일 DB에서 최종 SQL을 읽기 전용으로 대조해 행 수와 주요 결과 일치를 확인했으며, 대조 실행 시간을 사용자 시간으로 대체하지 않았습니다.

### 오류 수정·핵심 개념과 해석

처음에는 순위 차이 자체에 high_gap_video_count라는 이름을 붙여 영상 수로 해석했습니다. 하지만 81 − 16 = 65는 한 영상의 순위 차이이고, 조건을 만족하는 영상 수는 아닙니다.

첫 시도의 CTE에는 COUNT(\*)와 영상별 순위 계산을 함께 넣었고, 바깥 WHERE로 불충족 영상을 제외했습니다. 비율식의 ROUND 괄호와 같은 SELECT에서 만든 별칭 사용도 수정 대상이었습니다. 이 시도의 실제 DB 오류 메시지는 공유되지 않았습니다.

```sql
-- 첫 시도의 핵심 식: 영상 수가 아니라 영상별 순위 차이
CAST(total_rank AS SIGNED) - CAST(daily_rank AS SIGNED)
```

CTE에서는 영상별 두 순위를 유지하고, 바깥에서는 COUNT(\*)로 전체를 셉니다. 조건부 COUNT로 차이 >= 10인 영상만 별도로 셉니다. 바깥 WHERE를 제거해 전체 89개를 분모에 유지했습니다.

89개 중 21개이며 21 ÷ 89 × 100 = 23.60%입니다. 이것은 누적 순위가 10위 이내인 영상의 비율도, 전날 대비 순위 상승 영상의 비율도 아닙니다.
</details>

<details>
<summary>🔎 오늘 꼭 이해할 부분 — CAST·조건부 COUNT·순위와 필터</summary>

## CAST의 뜻과 사용 시점

CAST(값 AS 자료형)은 값을 지정한 자료형으로 변환하는 표현입니다. 계산·비교에 필요한 자료형이 현재 표현식의 자료형과 다를 때 사용합니다.

```sql
CAST(total_rank AS SIGNED)
```

SIGNED는 음수도 표현할 수 있는 정수형입니다. 이번에는 조회수가 아니라 RANK 결과를 변환했습니다. 현재 MySQL의 RANK 결과는 unsigned 정수형이므로 설정에 따라 음수가 나오는 뺄셈에서 범위 오류가 발생할 수 있습니다. 이 세션에서 CAST 없는 실패 오류를 실제로 재현한 기록은 없으므로 오류가 발생했다고 단정하지 않습니다.

| 가상 누적 순위 | 가상 전일 순위 | 누적 − 전일 | 의미 |
| --- | --- | --- | --- |
| 81 | 16 | 65 | 전일 기준에서 상대적으로 더 높은 위치 |
| 11 | 1 | 10 | 차이 10으로 포함 |
| 2 | 10 | -8 | 차이 음수로 제외 |

두 조회수가 모두 양수여도 2 − 10 = -8이 될 수 있습니다. 조건을 검사하려면 먼저 뺄셈을 평가해야 하므로 결과에서 양수만 남긴다는 이유로 계산 중 음수 가능성이 사라지지 않습니다.

다른 예: 숫자로 처리할 문자열을 정수로 변환하거나, 날짜 형식 문자열을 DATE로 변환할 때 CAST를 사용할 수 있습니다. 입력 형식이 실제로 변환 가능한지와 경고·실패 여부는 확인해야 합니다.

```sql
-- 구조 설명 예시
SELECT CAST('123' AS SIGNED) AS number_value;
SELECT CAST('2026-11-05' AS DATE) AS date_value;
```

CAST는 자료형 변환, ROUND는 반올림입니다. 같은 기능이 아닙니다.

## 전체 순위 계산 후 특정 영상 조회

한 쿼리 단계에서 WHERE가 영상을 한 개로 줄이면 그 단계의 RANK 비교 대상도 한 개입니다. CTE에서 전체 순위를 계산한 뒤 바깥에서 특정 영상을 선택하면 원래 전체 순위를 유지합니다.

## CASE WHEN을 쓰는 이유

전체 행은 유지하면서 조건 충족 행만 따로 세기 위해 사용합니다. 조건 충족 시 1, 불충족 시 NULL을 만들고 COUNT는 NULL을 제외합니다.

가상 차이가 65·14·3·-8인 네 영상이면 CASE 결과는 1·1·NULL·NULL입니다. COUNT(\*)는 4, 조건부 COUNT는 2, 비율은 50%입니다. WHERE로 먼저 필터링하면 분모도 2가 됩니다.

COUNT(\*)는 행 수, COUNT(표현식)는 NULL이 아닌 표현식의 수입니다. 0도 세므로 조건부 COUNT에 ELSE 0을 넣으면 불충족 행까지 포함될 수 있습니다.

## RANK의 정렬과 마지막 ORDER BY

OVER 안 ORDER BY는 순위 계산 기준입니다. 마지막 ORDER BY는 화면 표시 순서입니다. 전체 요약 한 행은 마지막 ORDER BY가 필요 없지만 RANK 안의 정렬 기준은 필요합니다.

## 음악 분석의 집계 단위

Spotify는 개별 트랙, YouTube는 개별 공식 영상입니다. 현재 500개 트랙에서 제목에 Remaster가 포함된 행은 290개, 그 외는 210개였으며, 그 외가 모두 원본 음원이라는 뜻은 아닙니다. 라이브·믹스·데모·메들리를 임의로 합산하거나 제목 표기를 먼저 지우지 않습니다.

이 세션은 같은 음원의 플랫폼 효과나 순위 차이의 원인을 검증하지 않았습니다. 누적 재생·조회 수와 전일 조회 수는 서로 다른 지표이고, 유튜브 조회 수는 고유 시청자 수가 아닙니다.
</details>

<details>
<summary>🧠 결과 요약·다음 분석</summary>

| 문제 | 최종 결과 |
| --- | --- |
| 1 | Spotify 상위 10트랙 |
| 2 | YouTube 전일 상위 10영상과 두 순위 |
| 3 | HCTS 2019 Mix: 누적 3위·전일 3위 |
| 4 | 누적 − 전일 순위 차이 10 이상: 21영상 |
| 5 | 전체 89영상 중 21영상: 23.60% |

### 오늘 분석의 흐름

트랙 순위 → 영상의 두 지표 순위 → 특정 영상의 전체 순위 → 상대적 순위 차이 → 차이 조건 충족 영상의 전체 비중으로 이어졌습니다. Spotify와 YouTube 자료는 각 플랫폼 안에서 별도로 분석했습니다.

### 다음에 확인할 부분 — 미실행

- [ ] 게시 개월 수의 기준일·월 포함 규칙과 0 나누기 처리
- [ ] 누적 조회수와 게시 기간당 평균 조회수의 차이·한계
- [ ] Spotify 트랙과 YouTube 영상의 버전 연결 기준
- [ ] 다른 영상으로 전체 순위 계산 후 필터 재풀이
- [ ] 순위 차이 조건을 바꾼 조건부 COUNT·비율 재풀이

기간당 평균도 콘텐츠 버전·노출·시대 효과를 통제한 지표는 아닙니다. 실제 전주 대비 순위 변화는 동일 지표의 여러 시점 데이터가 필요합니다.
</details>
</details>
