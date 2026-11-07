-- Day23: final user-written music SQL; collected snapshot, not live platform totals.
-- Database: music_study. Read-only verification: 2026-11-08.

-- Exercise 1
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

-- Exercise 2
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

-- Exercise 3
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

-- Exercise 4
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

-- Exercise 5
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
