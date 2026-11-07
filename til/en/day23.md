# Day 23 — Music rankings, CTEs, CAST and conditional aggregation

[한국어](../ko/day23.md) · [Index](../../README.md)

## Why music data?

This session connects SQL practice to a Beatles content-planning question from Numberlog Music: how do relative positions differ between cumulative reach and a particular day's activity? Previously learned CTEs, RANK and conditional aggregation are applied to a new domain, with explicit track/video grain and denominators. This is a descriptive SQL exercise connected to content planning; content production and SQL completion have separate outcomes.

The local music_study snapshot is recorded as collected from kworb on 2026-11-05: 500 Spotify tracks and 89 official YouTube videos. Hot100 is not used in this session. Versions are not merged. Same-recording cross-platform matching, publication-age averages and causal explanations remain follow-up tasks.

```bash
mysql -u root -p
```

```sql
USE music_study;
```

## Exercise 1 — Spotify top ten individual tracks

### Table and row grain

beatles_spotify_tracks: one row is one individual Spotify track, including distinct versions. The snapshot has 500 rows and 500 distinct track_id values. Required fields: row_id INT PRIMARY KEY, track_id VARCHAR(22), title VARCHAR(255), streams BIGINT; all are non-NULL. streams is a cumulative play count, not a unique-listener count.

**Question and conditions.** Use only beatles_spotify_tracks. Rank all 500 tracks by streams descending with RANK; equal counts share a rank and the next rank is skipped. Do not combine versions. Return exactly ten rows, ordered by streams descending then row_id ascending; do not include extra boundary ties. Keep original integer counts. Return stream_rank, track_id, title and streams. One output row is one individual track.

**Example — fictional.** Fictional tracks with 900000, 800000 and 800000 streams receive ranks 1, 2 and 2; the next lower track is rank 4.

### Final query recorded in the journal

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

### Recorded output (source excerpt)

| stream\_rank | track\_id | title | streams |
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

User-recorded execution: 10 rows in 0.03 seconds. Read-only database checks matched the full submitted table; these checks do not replace the original runtime.

### Errors, correction and interpretation

The optional CTE is valid; using stream_rank as both a CTE name and a result-column name is also valid. Only streams determines ranking ties. row_id is a display tie-breaker. Here Comes The Sun - Remastered 2009 is first among collected tracks with 1954864380 streams, not a sum of every version of the song.

## Exercise 2 — YouTube cumulative and prior-day rankings

### Table and row grain

beatles_youtube_videos: one row is one official YouTube video; different videos of the same song remain separate. Required fields: video_id VARCHAR(11) PRIMARY KEY, title VARCHAR(255), views BIGINT (all non-NULL), and views_yesterday BIGINT (nullable by schema). The 89-row snapshot has no actual NULLs in either count. Prior-day means the day associated with the collected source snapshot, not today. Views are not unique viewers.

**Question and conditions.** Use only beatles_youtube_videos. Calculate independent cumulative and prior-day RANK values over all 89 videos, descending by each count. Equal counts tie and the next rank is skipped. Do not combine videos of the same song. Display exactly ten rows ordered by views_yesterday descending then video_id ascending, without extra boundary ties. Return total_rank, daily_rank, video_id, title, views and views_yesterday as original integers. One row is one video.

**Example — fictional.** A fictional video may be cumulative rank 3 but daily rank 1, while another is cumulative rank 1 and daily rank 2.

### Final query recorded in the journal

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

### Recorded output (source excerpt)

| total\_rank | daily\_rank | video\_id | title | views | views\_yesterday |
| --- | --- | --- | --- | --- | --- |
| 11 | 1 | CGj85pVzRJs | The Beatles - The Beatles - Let It Be (Official Music Video) \[Remastered 2015\] | 135114357 | 168360 |
| 1 | 2 | NCtzkaL2t\_Y | The Beatles - The Beatles - Don't Let Me Down (Live Performance) \[Mono / 2009 Remaster\] | 585732182 | 121536 |
| 3 | 3 | KQetemT1sWc | The Beatles - Here Comes The Sun (2019 Mix) | 215127242 | 79200 |
| 2 | 4 | A\_MjCqQoLLA | The Beatles - The Beatles - Hey Jude (Official Music Video) \[Remastered 2015\] | 459320807 | 64944 |
| 19 | 5 | Opxhh9Oh3rg | The Beatles - The Beatles - Now And Then (Official Music Video) | 87609220 | 41616 |
| 8 | 6 | UelDrZ1aFeY | The Beatles - Something | 156849566 | 39480 |
| 5 | 7 | 2Q\_ZzBGPdqE | The Beatles - Help! | 179934235 | 39264 |
| 14 | 8 | wXTJBr9tt8Q | The Beatles - Yesterday (Live With Spoken Word Intro, New York) \[Remastered 2015\] | 115386665 | 36840 |
| 7 | 9 | 45cYwDMibGo | The Beatles - Come Together | 165382643 | 34416 |
| 12 | 10 | m2uTFF\_3MaA | The Beatles - Yellow Submarine | 127202300 | 25632 |

User-recorded execution: 10 rows in 0.06 seconds. Read-only database checks matched the full submitted table; these checks do not replace the original runtime.

### Errors, correction and interpretation

The submitted query calculates the cumulative rank in the CTE and daily rank outside. It remains correct because no rows are filtered between those stages. Let It Be is cumulative rank 11 and daily rank 1; Don't Let Me Down is cumulative rank 1 and daily rank 2.

## Exercise 3 — A selected video within the full ranking

### Table and row grain

beatles_youtube_videos: one row is one official YouTube video; different videos of the same song remain separate. Required fields: video_id VARCHAR(11) PRIMARY KEY, title VARCHAR(255), views BIGINT (all non-NULL), and views_yesterday BIGINT (nullable by schema). The 89-row snapshot has no actual NULLs in either count. Prior-day means the day associated with the collected source snapshot, not today. Views are not unique viewers.

**Question and conditions.** Use beatles_youtube_videos and a CTE. Both cumulative and prior-day RANK values must compare all 89 videos, ordered descending by the corresponding count with ties and gaps. In the final result retain only video_id = 'KQetemT1sWc' (Here Comes The Sun, 2019 Mix). Do not combine other videos; keep integer counts. Return total_rank, daily_rank, video_id, title, views and views_yesterday. One output row is the selected video, while the ranking universe remains the full video set.

**Example — fictional.** A fictional selected video at cumulative rank 7 and daily rank 4 produces one output row with 7 and 4. One output row does not mean one input row for ranking.

### Final query recorded in the journal

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

### Recorded output (source excerpt)

| total\_rank | daily\_rank | video\_id | title | views | views\_yesterday |
| --- | --- | --- | --- | --- | --- |
| 3 | 3 | KQetemT1sWc | The Beatles - Here Comes The Sun (2019 Mix) | 215127242 | 79200 |

User-recorded execution: 1 rows in 0.07 seconds. Read-only database checks matched the full submitted table; these checks do not replace the original runtime.

### Errors, correction and interpretation

The initial attempt computed only the cumulative rank in the CTE, then filtered to this video before calculating daily RANK outside. It returned cumulative rank 3 and daily rank 1: the outer window compared only one remaining video. Moving both rank calculations into the CTE fixes the comparison universe. The final user-selected query has no LIMIT, returning 3 and 3. The remaining final ORDER BY is unnecessary for a primary-key selection but not incorrect.

## Exercise 4 — Videos with a rank gap of at least ten

### Table and row grain

beatles_youtube_videos: one row is one official YouTube video; different videos of the same song remain separate. Required fields: video_id VARCHAR(11) PRIMARY KEY, title VARCHAR(255), views BIGINT (all non-NULL), and views_yesterday BIGINT (nullable by schema). The 89-row snapshot has no actual NULLs in either count. Prior-day means the day associated with the collected source snapshot, not today. Views are not unique viewers.

**Question and conditions.** Use beatles_youtube_videos and a CTE. Calculate two descending RANK values over all videos, preserving ties and gaps. Define rank_gap as total_rank minus daily_rank; it can be negative. Keep every video with rank_gap >= 10, not merely ten rows. Order rank_gap descending then video_id ascending. Return video_id, title, total_rank, daily_rank and rank_gap. One row is one qualifying video.

**Example — fictional.** A fictional video at cumulative rank 40 and daily rank 8 has gap 32 and qualifies; ranks 15 and 12 have gap 3 and do not.

### Final query recorded in the journal

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

### Recorded output (source excerpt)

| video\_id | title | total\_rank | daily\_rank | rank\_gap |
| --- | --- | --- | --- | --- |
| \_HJIndFgLG4 | The Beatles - In My Life - 2026 Mix (Visualiser) | 81 | 16 | 65 |
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
| hgJ7dmr\_ysU | The Beatles - For No One | 50 | 38 | 12 |
| R9ncBUcInTM | The Beatles - Good Day Sunshine | 62 | 50 | 12 |
| 9g2eU9YGwWQ | The Beatles - And Your Bird Can Sing | 53 | 42 | 11 |
| m4BuziKGMy4 | The Beatles - Tomorrow Never Knows | 54 | 43 | 11 |
| CGj85pVzRJs | The Beatles - The Beatles - Let It Be (Official Music Video) \[Remastered 2015\] | 11 | 1 | 10 |

User-recorded execution: 21 rows in 0.06 seconds. Read-only database checks matched the full submitted table; these checks do not replace the original runtime.

### Errors, correction and interpretation

CAST applies to ranks, not views. The signed difference can be negative, so the submitted query casts both rank values AS SIGNED before subtracting. The first row has 81 - 16 = 65. This compares two metrics, not a rise of 65 positions since yesterday. The threshold is a rank gap of at least ten, not membership in the cumulative top ten.

## Exercise 5 — Share of videos meeting the rank-gap condition

### Table and row grain

beatles_youtube_videos: one row is one official YouTube video; different videos of the same song remain separate. Required fields: video_id VARCHAR(11) PRIMARY KEY, title VARCHAR(255), views BIGINT (all non-NULL), and views_yesterday BIGINT (nullable by schema). The 89-row snapshot has no actual NULLs in either count. Prior-day means the day associated with the collected source snapshot, not today. Views are not unique viewers.

**Question and conditions.** Use beatles_youtube_videos and a CTE. Compute cumulative and prior-day descending RANK over the complete video set with ties and gaps. The numerator counts videos whose total_rank minus daily_rank is at least ten. The denominator counts all videos, including those that do not qualify. Derive counts from the data, not literal constants. Return a single summary row: total_video_count, high_gap_video_count and high_gap_rate = qualifying count / total count * 100, rounded only at the end to two decimals. No final result ordering is required.

**Example — fictional.** In a fictional set of 100 videos with 20 qualifying, the percentage is 20.00%. Nonqualifying videos still belong in the denominator.

### Final query recorded in the journal

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

### Recorded output (source excerpt)

| total\_video\_count | high\_gap\_video\_count | high\_gap\_rate |
| --- | --- | --- |
| 89 | 21 | 23.60 |

User-recorded execution: 1 rows in 0.08 seconds. Read-only database checks matched the full submitted table; these checks do not replace the original runtime.

### Errors, correction and interpretation

The first attempt labeled the per-video rank difference as a qualifying video count. A difference such as 65 belongs to one video and is not a count of qualifying videos. The first CTE also mixed COUNT(*) with individual-video window calculations; the outer WHERE removed nonqualifying denominator rows, and ROUND parentheses / reuse of a same-SELECT alias needed correction. No executed database error text was supplied for these attempts. The final query keeps video-level ranks in the CTE, counts all 89 rows outside and uses conditional COUNT to count 21 qualifying rows. The final percentage is 21 / 89 * 100 = 23.60%.

## CAST: meaning, purpose and examples

CAST(value AS type) converts a value to a specified data type for calculation or comparison. CAST(total_rank AS SIGNED) converts a rank to an integer type that can represent negative values. The subtraction concerns ranks, not viewer counts: cumulative rank 2 minus daily rank 10 is -8 even though both view counts are positive. MySQL RANK results are unsigned integers, so negative subtraction can fail depending on settings. No CAST-free failure was actually reproduced in this session; this is the reason for the defensive conversion, not a claimed observed error.

| Fictional total rank | Fictional daily rank | Difference | Treatment |
| --- | --- | --- | --- |
| 81 | 16 | 65 | Qualifies |
| 11 | 1 | 10 | Qualifies |
| 2 | 10 | -8 | Excluded |

The difference must be evaluated to test the predicate, even if only positive differences are finally retained. Other uses include converting a numeric string to an integer or a compatible date string to DATE; validate input formats and warnings.

```sql
-- Illustrative conversion examples
SELECT CAST('123' AS SIGNED) AS number_value;
SELECT CAST('2026-11-05' AS DATE) AS date_value;
```

CAST converts types; ROUND rounds numbers.

## Conditional counts, filtering and ranking

WHERE in a query stage filters rows before its window calculation. Rank all videos in the CTE, then filter a selected video outside to retain its full-set ranks. COUNT(*) counts rows; COUNT(expression) counts non-NULL expression values, including zero. For fictional gaps 65, 14, 3 and -8, a conditional CASE yields 1, 1, NULL, NULL: the total is 4, qualifying count 2 and share 50%. Filtering qualifying rows first would reduce the denominator to 2. ELSE 0 inside conditional COUNT would count nonqualifying rows too.

OVER ORDER BY defines the ranking metric; final ORDER BY defines display order. A single summary row needs no final ordering, but window ranks still need their metric order.

## Music interpretation and next analysis

Spotify grain is an individual track and YouTube grain an individual official video. In the 500-track snapshot, 290 titles contain Remaster and 210 do not; the latter are not all verified original versions. Live, mixes, demos and medleys are not arbitrarily merged. Spotify Remastered 2009 and YouTube 2019 Mix are different content. Views are not unique viewers. Prior-day counts refer to the source snapshot.

The flow is track ranking → two video metric rankings → a selected video's position → metric rank gaps → the share meeting the gap condition. The 21/89 = 23.60% result is not a day-over-day rank increase or a causal claim. True temporal change needs the same metric at multiple dates.

Next, define the reference date and partial-month rule before calculating publication months and views per month. Check zero denominators, NULLs and unrounded ranking. Even an age-based average does not control exposure, content version or historical effects. Same-content cross-platform joins, publication-month averages and Hot100 LAG/LEAD have not been completed in this session.
