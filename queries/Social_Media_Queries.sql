-- THE DATA ANALYSIS USING SQL PROGRAM - TUWAIQ ACADEMY 


USE social_media;

-- 1. What is the location of each user in the social media database?
SELECT users.user_id, users.username, post.location
FROM users
INNER JOIN post
ON users.user_id = post.user_id;


-- 2. Which hashtag has the highest number of followers in the social media database?
-- (Give me the first 5 ones).
SELECT h.hashtag_name,
    COUNT(hf.user_id) AS followers_count
FROM hashtags AS h
JOIN hashtag_follow AS hf
    ON h.hashtag_id = hf.hashtag_id
GROUP BY h.hashtag_id, h.hashtag_name
ORDER BY followers_count DESC
LIMIT 5;


-- 3. What are the most frequently used hashtags in the social media database?
-- (Give me the used for all hashtags and determine which one is the most).
SELECT h.hashtag_name,
    COUNT(pt.post_id) AS usage_count
FROM hashtags AS h
JOIN post_tags AS pt
    ON h.hashtag_id = pt.hashtag_id
GROUP BY h.hashtag_id, h.hashtag_name
ORDER BY usage_count DESC;


-- 4. Who is the most inactive user (or the user with the least activity) in the social media database? 
-- (Give me the first 5 and determine which one is the least).
SELECT u.user_id, u.username,
    COUNT(p.post_id) AS total_posts
FROM users AS u
LEFT JOIN post AS p
    ON u.user_id = p.user_id
GROUP BY u.user_id, u.username
ORDER BY total_posts ASC
LIMIT 7;


-- 5. Which posts have received the highest number of likes in the social media database?
SELECT p.post_id, p.caption,
    COUNT(pl.user_id) AS total_likes
FROM post AS p
LEFT JOIN post_likes AS pl
    ON p.post_id = pl.post_id
GROUP BY p.post_id, p.caption
ORDER BY total_likes DESC;


-- 6. What is the average number of posts per user in the social media database?
SELECT AVG(total_posts) AS average_posts_per_user
FROM (
    SELECT u.user_id,
        COUNT(p.post_id) AS total_posts
    FROM users AS u
    LEFT JOIN post AS p
        ON u.user_id = p.user_id
    GROUP BY u.user_id
) AS user_posts;


-- 7. How many times has each user logged in to the social media platform?
SELECT u.user_id, u.username,
    COUNT(l.login_id) AS total_logins
FROM users AS u
LEFT JOIN login AS l
    ON u.user_id = l.user_id
GROUP BY u.user_id, u.username
ORDER BY total_logins DESC;


-- 8. Are there any users who have liked every single post in the social media database?
SELECT u.user_id, u.username,
    COUNT(pl.post_id) AS total_likes
FROM users AS u
INNER JOIN post_likes AS pl
    ON u.user_id = pl.user_id
GROUP BY u.user_id, u.username
HAVING COUNT(pl.post_id) = (
    SELECT COUNT(*)
    FROM post
);


-- 9. Write a SQL query to display every post along with the username of its author, the total number of likes,
-- and the total number of comments.
SELECT p.post_id, p.caption, u.username, l.total_likes, c.total_comments

FROM post AS p
INNER JOIN users AS u
    ON p.user_id = u.user_id

LEFT JOIN
(
    SELECT post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
) AS l
ON p.post_id = l.post_id

LEFT JOIN
(
    SELECT post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
) AS c
ON p.post_id = c.post_id
ORDER BY p.post_id;
-- this query consumes less memory because it counts likes and comments separately and then merges them.


-- 10. Write a SQL query to find all users who have never created a post.
SELECT u.user_id, u.username
FROM users AS u
WHERE NOT EXISTS
(
    SELECT 1
    FROM post AS p
    WHERE p.user_id = u.user_id
);


-- 11. Write a SQL query to find the five users whose posts have received the highest total number of likes.
SELECT u.user_id, u.username,
    COUNT(pl.user_id) AS total_likes
    
FROM users AS u
INNER JOIN post AS p
    ON u.user_id = p.user_id
LEFT JOIN post_likes AS pl
    ON p.post_id = pl.post_id
    
GROUP BY u.user_id, u.username
ORDER BY total_likes DESC
LIMIT 5;


-- 12. Write a SQL query to display the latest post created by each user, 
-- including the username, post caption, location, and creation date.
SELECT u.username, p.caption, p.location, p.created_at

FROM users AS u
INNER JOIN
(
    SELECT
        user_id,
        MAX(created_at) AS latest_post
    FROM post
    GROUP BY user_id
) AS latest
    ON u.user_id = latest.user_id

INNER JOIN post AS p
    ON p.user_id = latest.user_id
   AND p.created_at = latest.latest_post;
   
   
-- 13. Write a SQL query to find users whose number of followers is greater than the average follower count of all users.
WITH followers AS (
    SELECT u.user_id, u.username,
        COUNT(f.follower_id) AS followers
        
    FROM users AS u
    LEFT JOIN follows AS f
        ON u.user_id = f.followee_id
        
    GROUP BY u.user_id, u.username
)

SELECT user_id, username, followers
    
FROM (
    SELECT user_id, username, followers,
        AVG(followers) OVER () AS avg_followers
    FROM followers
) AS ranked

WHERE followers > avg_followers;


-- 14. Write a SQL query to find the post or posts that have received the highest number of likes.
WITH likes AS (
    SELECT p.post_id, p.caption,
        COUNT(pl.user_id) AS total_likes
        
    FROM post AS p
    LEFT JOIN post_likes AS pl
        ON p.post_id = pl.post_id
        
    GROUP BY p.post_id, p.caption
)

SELECT post_id, caption, total_likes
FROM likes

WHERE total_likes = (
    SELECT MAX(total_likes)
    FROM likes
);


-- 15. Write a SQL query to find hashtags that have been used in at least three different posts.
-- Display each hashtag, the number of posts using it, and the number of users following it.
WITH post_count AS
(
    SELECT hashtag_id,
        COUNT(*) AS total_posts
    FROM post_tags
    GROUP BY hashtag_id
),

followers_count AS
(
    SELECT hashtag_id,
        COUNT(*) AS total_followers
    FROM hashtag_follow
    GROUP BY hashtag_id
)

SELECT
    TRIM(h.hashtag_name) AS hashtag_name,
    pc.total_posts,
    COALESCE(fc.total_followers,0) AS total_followers
    
FROM hashtags AS h
JOIN post_count AS pc
    ON h.hashtag_id = pc.hashtag_id
    
LEFT JOIN followers_count AS fc
    ON h.hashtag_id = fc.hashtag_id
    
WHERE pc.total_posts >= 3
ORDER BY pc.total_posts DESC;
-- Hashtag names are trimmed during presentation to eliminate leading/trailing spaces without modifying the source data. 
-- Missing follower counts are displayed as 0 using COALESCE



-- 16. Write a SQL query to find users who bookmarked a post that they also liked. 
-- Display the username, post ID, and post caption.
SELECT u.username, p.post_id, p.caption

FROM bookmarks AS b
INNER JOIN post_likes AS pl
    ON b.user_id = pl.user_id
   AND b.post_id = pl.post_id
INNER JOIN users AS u
    ON b.user_id = u.user_id
INNER JOIN post AS p
    ON b.post_id = p.post_id;
-- To verify, we took a look at one result's record through each of the bookmark & post_likes tables 
    
    
-- 17. Write a SQL query to find comments that have received more likes than the average number of likes received by all comments.
WITH comment_likes_count AS
(
    SELECT comment_id,
        COUNT(*) AS total_likes
    FROM comment_likes
    GROUP BY comment_id
)

SELECT c.comment_id, c.comment_text, clc.total_likes

FROM comments AS c
JOIN comment_likes_count AS clc
    ON c.comment_id = clc.comment_id
    
WHERE clc.total_likes >
(
    SELECT AVG(total_likes)
    FROM comment_likes_count
)
ORDER BY clc.total_likes DESC;

-- To verify result, we check the average number of likes.
WITH comment_likes_count AS
(
    SELECT comment_id,
        COUNT(*) AS total_likes
    FROM comment_likes
    GROUP BY comment_id
)

SELECT AVG(total_likes) AS average_likes
FROM comment_likes_count;



-- 18. Write a SQL query to find pairs of users who follow each other. Display each pair only once.
SELECT
    u1.username AS user1,
    u2.username AS user2
    
FROM follows AS f1
JOIN follows AS f2
    ON f1.follower_id = f2.followee_id
   AND f1.followee_id = f2.follower_id
   
JOIN users AS u1
    ON f1.follower_id = u1.user_id
JOIN users AS u2
    ON f1.followee_id = u2.user_id
    
WHERE f1.follower_id < f1.followee_id;

-- check result
SELECT *
FROM follows
WHERE follower_id = 45;
SELECT *
FROM follows
WHERE followee_id = 45;


					                   -- =========================================
									   --     Additional Business SQL Analysis
                                       -- =========================================  
                                       
                                                         
									   --    First: User Performance Analytics 
-- =====================================================================================================================================================
-- 19. Users above average likes

-- Business Question:
-- Which users receive more likes than the average user?

-- Business Value:
-- Identify users who perform above average based on the total likes
SELECT u.user_id, u.username,
    COUNT(pl.post_id) AS total_likes
    
FROM users AS u
JOIN post AS p
    ON u.user_id = p.user_id
LEFT JOIN post_likes AS pl
    ON p.post_id = pl.post_id
    
GROUP BY u.user_id, u.username
HAVING COUNT(pl.post_id) >
(
    SELECT AVG(user_likes)
    FROM
    (
        SELECT
            COUNT(pl.post_id) AS user_likes
        FROM users AS u
        JOIN post AS p
            ON u.user_id = p.user_id
        LEFT JOIN post_likes AS pl
            ON p.post_id = pl.post_id
        GROUP BY u.user_id
    ) AS avg_likes
)
ORDER BY total_likes DESC;


-- check result by check average user likes
SELECT 
    AVG(user_likes) AS avg_likes
FROM
    (SELECT 
        COUNT(pl.post_id) AS user_likes
    FROM users AS u
    JOIN post AS p ON u.user_id = p.user_id
    LEFT JOIN post_likes AS pl ON p.post_id = pl.post_id
    GROUP BY u.user_id) AS t;


-- =====================================================================================================================================================
-- 20. Highest average likes per post

-- Business Question:
-- Which users have the highest average likes per post?

-- Business Value:
-- Identify users who consistently create high-performing content by measuring the average likes received per post.
WITH likes_per_post AS
(
    SELECT post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
)

SELECT u.user_id, u.username,
    COUNT(p.post_id) AS total_posts,
    SUM(COALESCE(lp.total_likes,0)) AS total_likes,
    ROUND(AVG(COALESCE(lp.total_likes,0)),2) AS avg_likes_per_post

FROM users u
JOIN post p
    ON u.user_id = p.user_id
LEFT JOIN likes_per_post lp
    ON p.post_id = lp.post_id
    
GROUP BY u.user_id, u.username
ORDER BY avg_likes_per_post DESC;


											 --   Second: Content Performance Analytics 
-- =====================================================================================================================================================
-- 21. Posts above average engagement

-- Business Question:
-- Which posts have higher engagement than the platform average?

-- Business Value:
-- Identify posts that perform above average based on total engagement (likes + comments).
WITH likes_count AS
(
    SELECT post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),

comments_count AS
(
    SELECT post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),

engagement AS
(
    SELECT p.post_id, p.caption, u.username,

        COALESCE(l.total_likes,0) AS total_likes,
        COALESCE(c.total_comments,0) AS total_comments,

        COALESCE(l.total_likes,0) +
        COALESCE(c.total_comments,0) AS total_engagement

    FROM post p
    JOIN users u
        ON p.user_id = u.user_id
    LEFT JOIN likes_count l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count c
        ON p.post_id = c.post_id
)

SELECT *
FROM engagement
WHERE total_engagement >
(
    SELECT AVG(total_engagement)
    FROM engagement
)
ORDER BY total_engagement DESC;


-- check previuos query result by check average engagement
WITH likes_count AS
(
    SELECT post_id, COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),

comments_count AS
(
    SELECT post_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
)
SELECT AVG(COALESCE(l.total_likes,0) + COALESCE(c.total_comments,0)) AS average_engagement
FROM post p
LEFT JOIN likes_count l
    ON p.post_id = l.post_id
LEFT JOIN comments_count c
    ON p.post_id = c.post_id;


-- =====================================================================================================================================================
-- 22. Bookmarks vs Likes

-- Business Question:
-- Which posts are bookmarked more often than they are liked?

-- Business Value:
-- Identify valuable posts that users prefer to save rather than simply like,
-- helping understand long-term content value.
WITH likes_count AS
(
    SELECT post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),

bookmark_count AS
(
    SELECT post_id,
        COUNT(*) AS total_bookmarks
    FROM bookmarks
    GROUP BY post_id
)

SELECT p.post_id, u.username, p.caption,
    COALESCE(l.total_likes,0) AS total_likes,
    COALESCE(b.total_bookmarks,0) AS total_bookmarks

FROM post AS p
JOIN users AS u
    ON p.user_id = u.user_id
LEFT JOIN likes_count AS l
    ON p.post_id = l.post_id
LEFT JOIN bookmark_count AS b
    ON p.post_id = b.post_id

WHERE COALESCE(b.total_bookmarks,0) > COALESCE(l.total_likes,0)
ORDER BY total_bookmarks DESC;
-- In our data, the number of saves does not exceed the number of likes.


-- =====================================================================================================================================================
-- 23. Hashtag average engagement

-- Business Question:
-- Which hashtags generate the highest average engagement per post?

-- Business Value:
-- Identify the hashtags associated with the highest-performing content,
-- helping improve hashtag strategy and increase audience engagement.
WITH likes_count AS
(
    SELECT post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),

comments_count AS
(
    SELECT post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),

post_engagement AS
(
    SELECT p.post_id,
        COALESCE(l.total_likes,0) + COALESCE(c.total_comments,0) AS total_engagement

    FROM post p
    LEFT JOIN likes_count l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count c
        ON p.post_id = c.post_id
)

SELECT h.hashtag_name,
    COUNT(pt.post_id) AS total_posts,
    ROUND(AVG(pe.total_engagement),2) AS avg_engagement

FROM hashtags h
JOIN post_tags pt
    ON h.hashtag_id = pt.hashtag_id
JOIN post_engagement pe
    ON pt.post_id = pe.post_id

GROUP BY h.hashtag_id, h.hashtag_name
ORDER BY avg_engagement DESC;


										 --   Third: User Ranking & Activity Analytics 
-- =====================================================================================================================================================
-- 24. Best post per user (ROW_NUMBER)

-- Business Question:
-- What is the highest-performing post for each user based on total engagement?

-- Business Value:
-- Identify each user's top-performing post to understand which content generates the highest audience engagement.
WITH likes_count AS
(
    SELECT post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),

comments_count AS
(
    SELECT post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),

post_engagement AS
(
    SELECT p.post_id, p.user_id, p.caption, p.created_at,

        COALESCE(l.total_likes,0) +
        COALESCE(c.total_comments,0) AS total_engagement

    FROM post p
    LEFT JOIN likes_count l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count c
        ON p.post_id = c.post_id
)

SELECT username, post_id, caption, total_engagement

FROM
(
    SELECT u.username, pe.post_id, pe.caption, pe.total_engagement,

        ROW_NUMBER() OVER
        (
            PARTITION BY pe.user_id
            ORDER BY pe.total_engagement DESC, pe.created_at DESC, pe.post_id
        ) AS rn

    FROM post_engagement pe
    JOIN users u
        ON pe.user_id = u.user_id
) ranked_posts

WHERE rn = 1
ORDER BY total_engagement DESC, username;


-- =====================================================================================================================================================
-- 25. Top creators by engagement (RANK)

-- Business Question:
-- Who are the top content creators based on total engagement across all their posts?

-- Business Value:
-- Rank users by the total engagement generated by their posts to identify the platform's most influential creators.
WITH likes_count AS
(
    SELECT post_id,
        COUNT(*) AS total_likes
    FROM post_likes
    GROUP BY post_id
),

comments_count AS
(
    SELECT post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),

post_engagement AS
(
    SELECT p.post_id, p.user_id,

        COALESCE(l.total_likes,0) +
        COALESCE(c.total_comments,0) AS total_engagement

    FROM post p
    LEFT JOIN likes_count l
        ON p.post_id = l.post_id
    LEFT JOIN comments_count c
        ON p.post_id = c.post_id
),

user_engagement AS
(
    SELECT user_id,
        SUM(total_engagement) AS total_engagement
    FROM post_engagement
    GROUP BY user_id
)

SELECT
    RANK() OVER (
        ORDER BY total_engagement DESC
    ) AS user_rank,

    u.username,
    ue.total_engagement

FROM user_engagement ue
JOIN users u
    ON ue.user_id = u.user_id
ORDER BY user_rank;


-- check Ethan record
SELECT
    u.username,
    SUM(COALESCE(l.likes,0) + COALESCE(c.comments,0)) AS total_engagement
FROM users u
JOIN post p
    ON u.user_id = p.user_id
LEFT JOIN (
    SELECT post_id, COUNT(*) AS likes
    FROM post_likes
    GROUP BY post_id
) l
    ON p.post_id = l.post_id
LEFT JOIN (
    SELECT post_id, COUNT(*) AS comments
    FROM comments
    GROUP BY post_id
) c
    ON p.post_id = c.post_id
WHERE u.username = 'Ethan'
GROUP BY u.username;


-- =====================================================================================================================================================
-- 26. Most followed users (RANK)

-- Business Question:
-- Who are the most followed users on the platform?

-- Business Value:
-- Rank users based on their follower count to identify
-- the most influential accounts in the community.
WITH followers_count AS
(
    SELECT followee_id AS user_id,
        COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
)

SELECT

    RANK() OVER
    (
        ORDER BY total_followers DESC
    ) AS follower_rank,

    u.username,
    fc.total_followers

FROM followers_count fc
JOIN users u
    ON fc.user_id = u.user_id
ORDER BY
    follower_rank,
    username;
    
-- check Charlie   
SELECT
    COUNT(*) AS total_followers
FROM follows
WHERE followee_id =
(
    SELECT user_id
    FROM users
    WHERE username = 'Charlie'
); 

-- =====================================================================================================================================================
-- 27. Login gap analysis (LAG)

-- Business Question:
-- How much time passes between consecutive user logins?

-- Business Value:
-- Analyze the time gap between consecutive logins for each user
-- to better understand user activity patterns and login frequency.
WITH login_history AS
(
    SELECT l.user_id, u.username, l.login_time,

        LAG(l.login_time) OVER
        (
            PARTITION BY l.user_id
            ORDER BY l.login_time
        ) AS previous_login

    FROM login l
    JOIN users u
        ON l.user_id = u.user_id
)

SELECT username, login_time, previous_login,

    TIMESTAMPDIFF
    (
        SECOND,
        previous_login,
        login_time
    ) AS seconds_since_previous_login

FROM login_history
ORDER BY username, login_time;


-- =====================================================================================================================================================
-- 28. Next login analysis (LEAD)

-- Business Question:
-- When is each user's next login after the current one?

-- Business Value:
-- Analyze the sequence of user logins by identifying the next login
-- after each session, helping understand future user activity patterns.
WITH login_history AS
(
    SELECT l.user_id, u.username, l.login_time,

        LEAD(l.login_time) OVER
        (
            PARTITION BY l.user_id
            ORDER BY l.login_time
        ) AS next_login

    FROM login l
    JOIN users u
        ON l.user_id = u.user_id
)

SELECT username, login_time, next_login,
 
    TIMESTAMPDIFF
    (
        SECOND,
        login_time,
        next_login
    ) AS seconds_until_next_login

FROM login_history
ORDER BY username, login_time;


