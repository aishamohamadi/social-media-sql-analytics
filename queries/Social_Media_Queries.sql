/*
Project: Social Media SQL Analytics
Training context: Tuwaiq Academy - Data Analysis Using SQL

Database: social_media
SQL dialect: MySQL 8.0+

This file contains 28 analytical queries:
- Queries 01-18: Core SQL analysis
- Queries 19-28: Additional business-oriented analysis

Notes:
- The database contains sample data for learning and demonstration.
- Query results depend on the data loaded into the database.
- Window functions and common table expressions require MySQL 8.0+.
*/

USE social_media;


/* ============================================================
   SECTION 1 — CORE SQL ANALYSIS
   ============================================================ */


/* 01. Post locations by user
   Question: Which locations are associated with each user's posts?
*/
SELECT
    u.user_id,
    u.username,
    p.location
FROM users AS u
INNER JOIN post AS p
    ON u.user_id = p.user_id
ORDER BY u.username, p.location;


/* 02. Top five hashtags by follower count
   Question: Which hashtags have the largest number of followers?
*/
SELECT
    h.hashtag_name,
    COUNT(hf.user_id) AS followers_count
FROM hashtags AS h
INNER JOIN hashtag_follow AS hf
    ON h.hashtag_id = hf.hashtag_id
GROUP BY h.hashtag_id, h.hashtag_name
ORDER BY followers_count DESC, h.hashtag_name
LIMIT 5;


/* 03. Most frequently used hashtags
   Question: How often is each hashtag used across posts?
*/
SELECT
    h.hashtag_name,
    COUNT(pt.post_id) AS usage_count
FROM hashtags AS h
LEFT JOIN post_tags AS pt
    ON h.hashtag_id = pt.hashtag_id
GROUP BY h.hashtag_id, h.hashtag_name
ORDER BY usage_count DESC, h.hashtag_name;


/* 04. Users with the fewest posts
   Question: Which users have created the fewest posts?
*/
SELECT
    u.user_id,
    u.username,
    COUNT(p.post_id) AS total_posts
FROM users AS u
LEFT JOIN post AS p
    ON u.user_id = p.user_id
GROUP BY u.user_id, u.username
ORDER BY total_posts ASC, u.username
LIMIT 5;


/* 05. Posts ranked by number of likes
   Question: Which posts have received the most likes?
*/
SELECT
    p.post_id,
    p.caption,
    COUNT(pl.user_id) AS total_likes
FROM post AS p
LEFT JOIN post_likes AS pl
    ON p.post_id = pl.post_id
GROUP BY p.post_id, p.caption
ORDER BY total_likes DESC, p.post_id;


/* 06. Average number of posts per user
   Question: What is the average number of posts created by a user?
   Users with no posts are included in the calculation.
*/
SELECT
    AVG(user_posts.total_posts) AS average_posts_per_user
FROM (
    SELECT
        u.user_id,
        COUNT(p.post_id) AS total_posts
    FROM users AS u
    LEFT JOIN post AS p
        ON u.user_id = p.user_id
    GROUP BY u.user_id
) AS user_posts;


/* 07. Login count by user
   Question: How many times has each user logged in?
*/
SELECT
    u.user_id,
    u.username,
    COUNT(l.login_id) AS total_logins
FROM users AS u
LEFT JOIN login AS l
    ON u.user_id = l.user_id
GROUP BY u.user_id, u.username
ORDER BY total_logins DESC, u.username;


/* 08. Users who liked every post
   Question: Are there users who have liked every post in the database?
*/
SELECT
    u.user_id,
    u.username,
    COUNT(pl.post_id) AS total_likes
FROM users AS u
INNER JOIN post_likes AS pl
    ON u.user_id = pl.user_id
GROUP BY u.user_id, u.username
HAVING COUNT(pl.post_id) = (
    SELECT COUNT(*)
    FROM post
);


/* 09. Post-level likes and comments
   Question: What are the like and comment counts for each post?
*/
SELECT
    p.post_id,
    p.caption,
    u.username,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments
FROM post AS p
INNER JOIN users AS u
    ON p.user_id = u.user_id
LEFT JOIN (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
) AS l
    ON p.post_id = l.post_id
LEFT JOIN (
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
) AS c
    ON p.post_id = c.post_id
ORDER BY p.post_id;


/* 10. Users who have never created a post
    Question: Which users have not published any posts?
*/
SELECT
    u.user_id,
    u.username
FROM users AS u
WHERE NOT EXISTS (
    SELECT 1
    FROM post AS p
    WHERE p.user_id = u.user_id
)
ORDER BY u.username;


/* 11. Top five users by total likes received
    Question: Whose posts have received the highest total number of likes?
*/
SELECT
    u.user_id,
    u.username,
    COUNT(pl.user_id) AS total_likes
FROM users AS u
INNER JOIN post AS p
    ON u.user_id = p.user_id
LEFT JOIN post_likes AS pl
    ON p.post_id = pl.post_id
GROUP BY u.user_id, u.username
ORDER BY total_likes DESC, u.username
LIMIT 5;


/* 12. Latest post by each user
    Question: What is the latest post published by each user who has posted?
*/
SELECT
    u.username,
    p.caption,
    p.location,
    p.created_at
FROM users AS u
INNER JOIN (
    SELECT
        user_id,
        MAX(created_at) AS latest_post
    FROM post
    GROUP BY user_id
) AS latest
    ON u.user_id = latest.user_id
INNER JOIN post AS p
    ON p.user_id = latest.user_id
   AND p.created_at = latest.latest_post
ORDER BY u.username;


/* 13. Users with above-average follower counts
    Question: Which users have more followers than the average user?
    The average includes all users, including users with zero followers.
*/
WITH follower_counts AS (
    SELECT
        u.user_id,
        u.username,
        COUNT(f.follower_id) AS total_followers
    FROM users AS u
    LEFT JOIN follows AS f
        ON u.user_id = f.followee_id
    GROUP BY u.user_id, u.username
)
SELECT
    user_id,
    username,
    total_followers
FROM (
    SELECT
        user_id,
        username,
        total_followers,
        AVG(total_followers) OVER () AS average_followers
    FROM follower_counts
) AS user_metrics
WHERE total_followers > average_followers
ORDER BY total_followers DESC, username;


/* 14. Post or posts with the highest number of likes
    Question: Which post has the maximum number of likes?
    Ties are retained.
*/
WITH post_likes_count AS (
    SELECT
        p.post_id,
        p.caption,
        COUNT(pl.user_id) AS total_likes
    FROM post AS p
    LEFT JOIN post_likes AS pl
        ON p.post_id = pl.post_id
    GROUP BY p.post_id, p.caption
)
SELECT
    post_id,
    caption,
    total_likes
FROM post_likes_count
WHERE total_likes = (
    SELECT MAX(total_likes)
    FROM post_likes_count
);


/* 15. Hashtags used in at least three posts
    Question: Which hashtags appear in at least three posts, and how many
    users follow each of them?
*/
WITH hashtag_post_counts AS (
    SELECT
        hashtag_id,
        COUNT(*) AS total_posts
    FROM post_tags
    GROUP BY hashtag_id
),
hashtag_follower_counts AS (
    SELECT
        hashtag_id,
        COUNT(*) AS total_followers
    FROM hashtag_follow
    GROUP BY hashtag_id
)
SELECT
    TRIM(h.hashtag_name) AS hashtag_name,
    hp.total_posts,
    COALESCE(hf.total_followers, 0) AS total_followers
FROM hashtags AS h
INNER JOIN hashtag_post_counts AS hp
    ON h.hashtag_id = hp.hashtag_id
LEFT JOIN hashtag_follower_counts AS hf
    ON h.hashtag_id = hf.hashtag_id
WHERE hp.total_posts >= 3
ORDER BY hp.total_posts DESC, hashtag_name;


/* 16. Posts bookmarked and liked by the same user
    Question: Which users have both liked and bookmarked the same post?
*/
SELECT
    u.username,
    p.post_id,
    p.caption
FROM bookmarks AS b
INNER JOIN post_likes AS pl
    ON b.user_id = pl.user_id
   AND b.post_id = pl.post_id
INNER JOIN users AS u
    ON b.user_id = u.user_id
INNER JOIN post AS p
    ON b.post_id = p.post_id
ORDER BY u.username, p.post_id;


/* 17. Comments with above-average likes
    Question: Which comments received more likes than the average number
    of likes per comment?
    Comments with zero likes are included in the average.
*/
WITH comment_like_counts AS (
    SELECT
        c.comment_id,
        c.comment_text,
        COUNT(cl.user_id) AS total_likes
    FROM comments AS c
    LEFT JOIN comment_likes AS cl
        ON c.comment_id = cl.comment_id
    GROUP BY c.comment_id, c.comment_text
)
SELECT
    comment_id,
    comment_text,
    total_likes
FROM comment_like_counts
WHERE total_likes > (
    SELECT AVG(total_likes)
    FROM comment_like_counts
)
ORDER BY total_likes DESC, comment_id;


/* 18. Mutual follows
    Question: Which pairs of users follow each other?
    Each pair is returned once.
*/
SELECT
    u1.username AS user1,
    u2.username AS user2
FROM follows AS f1
INNER JOIN follows AS f2
    ON f1.follower_id = f2.followee_id
   AND f1.followee_id = f2.follower_id
INNER JOIN users AS u1
    ON f1.follower_id = u1.user_id
INNER JOIN users AS u2
    ON f1.followee_id = u2.user_id
WHERE f1.follower_id < f1.followee_id
ORDER BY user1, user2;


/* ============================================================
   SECTION 2 — ADDITIONAL BUSINESS-ORIENTED ANALYSIS
   ============================================================ */


/* ------------------------------------------------------------
   GROUP A — USER PERFORMANCE
   ------------------------------------------------------------ */


/* 19. Users with above-average likes received
    Business question: Which users receive more likes than the average user?
    The average includes all users, including users with no posts.
*/
WITH user_like_counts AS (
    SELECT
        u.user_id,
        u.username,
        COUNT(pl.post_id) AS total_likes
    FROM users AS u
    LEFT JOIN post AS p
        ON u.user_id = p.user_id
    LEFT JOIN post_likes AS pl
        ON p.post_id = pl.post_id
    GROUP BY u.user_id, u.username
)
SELECT
    user_id,
    username,
    total_likes
FROM (
    SELECT
        user_id,
        username,
        total_likes,
        AVG(total_likes) OVER () AS average_user_likes
    FROM user_like_counts
) AS user_metrics
WHERE total_likes > average_user_likes
ORDER BY total_likes DESC, username;


/* 20. Average likes per post by user
    Business question: Which users have the highest average likes per post?
    Only users who have published at least one post are included.
*/
WITH likes_per_post AS (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
)
SELECT
    u.user_id,
    u.username,
    COUNT(p.post_id) AS total_posts,
    SUM(COALESCE(lp.total_likes, 0)) AS total_likes,
    ROUND(AVG(COALESCE(lp.total_likes, 0)), 2) AS avg_likes_per_post
FROM users AS u
INNER JOIN post AS p
    ON u.user_id = p.user_id
LEFT JOIN likes_per_post AS lp
    ON p.post_id = lp.post_id
GROUP BY u.user_id, u.username
ORDER BY avg_likes_per_post DESC, u.username;


/* ------------------------------------------------------------
   GROUP B — CONTENT PERFORMANCE
   ------------------------------------------------------------ */


/* 21. Posts with above-average engagement
    Business question: Which posts perform above the platform average?
    Engagement is defined here as likes plus comments.
*/
WITH likes_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),
comments_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),
post_engagement AS (
    SELECT
        p.post_id,
        p.caption,
        u.username,
        COALESCE(l.total_likes, 0) AS total_likes,
        COALESCE(c.total_comments, 0) AS total_comments,
        COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)
            AS total_engagement
    FROM post AS p
    INNER JOIN users AS u
        ON p.user_id = u.user_id
    LEFT JOIN likes_count AS l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count AS c
        ON p.post_id = c.post_id
)
SELECT
    post_id,
    caption,
    username,
    total_likes,
    total_comments,
    total_engagement
FROM post_engagement
WHERE total_engagement > (
    SELECT AVG(total_engagement)
    FROM post_engagement
)
ORDER BY total_engagement DESC, post_id;


/* 22. Posts with more bookmarks than likes
    Business question: Which posts are bookmarked more often than liked?
*/
WITH likes_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),
bookmark_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_bookmarks
    FROM bookmarks
    GROUP BY post_id
)
SELECT
    p.post_id,
    u.username,
    p.caption,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(b.total_bookmarks, 0) AS total_bookmarks
FROM post AS p
INNER JOIN users AS u
    ON p.user_id = u.user_id
LEFT JOIN likes_count AS l
    ON p.post_id = l.post_id
LEFT JOIN bookmark_count AS b
    ON p.post_id = b.post_id
WHERE COALESCE(b.total_bookmarks, 0) > COALESCE(l.total_likes, 0)
ORDER BY total_bookmarks DESC, p.post_id;


/* 23. Average engagement by hashtag
    Business question: Which hashtags are associated with the highest
    average engagement per post?
    Engagement is defined as likes plus comments.
*/
WITH likes_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),
comments_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),
post_engagement AS (
    SELECT
        p.post_id,
        COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)
            AS total_engagement
    FROM post AS p
    LEFT JOIN likes_count AS l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count AS c
        ON p.post_id = c.post_id
)
SELECT
    h.hashtag_name,
    COUNT(pt.post_id) AS total_posts,
    ROUND(AVG(pe.total_engagement), 2) AS avg_engagement
FROM hashtags AS h
INNER JOIN post_tags AS pt
    ON h.hashtag_id = pt.hashtag_id
INNER JOIN post_engagement AS pe
    ON pt.post_id = pe.post_id
GROUP BY h.hashtag_id, h.hashtag_name
ORDER BY avg_engagement DESC, h.hashtag_name;


/* ------------------------------------------------------------
   GROUP C — RANKING AND ACTIVITY
   ------------------------------------------------------------ */


/* 24. Top-performing post for each user
    Business question: What is each user's highest-engagement post?
    ROW_NUMBER selects one post per user; ties are resolved by date and ID.
*/
WITH likes_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),
comments_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),
post_engagement AS (
    SELECT
        p.post_id,
        p.user_id,
        p.caption,
        p.created_at,
        COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)
            AS total_engagement
    FROM post AS p
    LEFT JOIN likes_count AS l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count AS c
        ON p.post_id = c.post_id
),
ranked_posts AS (
    SELECT
        u.username,
        pe.post_id,
        pe.caption,
        pe.total_engagement,
        ROW_NUMBER() OVER (
            PARTITION BY pe.user_id
            ORDER BY pe.total_engagement DESC, pe.created_at DESC, pe.post_id
        ) AS row_num
    FROM post_engagement AS pe
    INNER JOIN users AS u
        ON pe.user_id = u.user_id
)
SELECT
    username,
    post_id,
    caption,
    total_engagement
FROM ranked_posts
WHERE row_num = 1
ORDER BY total_engagement DESC, username;


/* 25. User ranking by total post engagement
    Business question: Who are the top creators based on total engagement?
    RANK preserves tied positions.
*/
WITH likes_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),
comments_count AS (
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),
post_engagement AS (
    SELECT
        p.post_id,
        p.user_id,
        COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)
            AS total_engagement
    FROM post AS p
    LEFT JOIN likes_count AS l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count AS c
        ON p.post_id = c.post_id
),
user_engagement AS (
    SELECT
        user_id,
        SUM(total_engagement) AS total_engagement
    FROM post_engagement
    GROUP BY user_id
)
SELECT
    RANK() OVER (
        ORDER BY ue.total_engagement DESC
    ) AS user_rank,
    u.username,
    ue.total_engagement
FROM user_engagement AS ue
INNER JOIN users AS u
    ON ue.user_id = u.user_id
ORDER BY user_rank, u.username;


/* 26. User ranking by follower count
    Business question: Who are the most-followed users?
    Accounts with at least one follower are ranked.
*/
WITH follower_counts AS (
    SELECT
        followee_id AS user_id,
        COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
)
SELECT
    RANK() OVER (
        ORDER BY fc.total_followers DESC
    ) AS follower_rank,
    u.username,
    fc.total_followers
FROM follower_counts AS fc
INNER JOIN users AS u
    ON fc.user_id = u.user_id
ORDER BY follower_rank, u.username;


/* 27. Time between consecutive logins (LAG)
    Business question: How much time passes between each user's logins?
    The first login for each user has no previous-login interval.
*/
WITH login_history AS (
    SELECT
        l.login_id,
        l.user_id,
        u.username,
        l.login_time,
        LAG(l.login_time) OVER (
            PARTITION BY l.user_id
            ORDER BY l.login_time, l.login_id
        ) AS previous_login
    FROM login AS l
    INNER JOIN users AS u
        ON l.user_id = u.user_id
)
SELECT
    username,
    login_time,
    previous_login,
    TIMESTAMPDIFF(
        SECOND,
        previous_login,
        login_time
    ) AS seconds_since_previous_login
FROM login_history
ORDER BY username, login_time, login_id;


/* 28. Time until the next login (LEAD)
    Business question: When does each user's next login occur?
    The final login for each user has no next-login interval.
*/
WITH login_history AS (
    SELECT
        l.login_id,
        l.user_id,
        u.username,
        l.login_time,
        LEAD(l.login_time) OVER (
            PARTITION BY l.user_id
            ORDER BY l.login_time, l.login_id
        ) AS next_login
    FROM login AS l
    INNER JOIN users AS u
        ON l.user_id = u.user_id
)
SELECT
    username,
    login_time,
    next_login,
    TIMESTAMPDIFF(
        SECOND,
        login_time,
        next_login
    ) AS seconds_until_next_login
FROM login_history
ORDER BY username, login_time, login_id;
