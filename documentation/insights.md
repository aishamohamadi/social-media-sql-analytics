# Social Media SQL Analytics — Key Insights

## Project Overview

This project explores a sample social media database using MySQL 8.0+. The analysis covers user activity, post performance, engagement, hashtag usage, follower relationships, bookmarks, and login sequences.

The findings below are based on the query outputs included with the project. They describe this dataset only and should not be interpreted as evidence of real-world social media behavior.

## Dataset Snapshot

| Metric | Result |
|---|---:|
| Users | 50 |
| Posts | 100 |
| Comments | 199 |
| Post likes | 1,707 |
| Average posts per user | 2.00 |
| Users with no posts | 5 |

## Key Findings

### User Performance

- **Ethan** received the highest number of likes across his posts, with **107**, followed by **Liam (92)**, **sunil (82)**, and **Freddie (81)**.
- The average number of likes received per user was **34.14**. This calculation includes all 50 users, including users with no posts.
- **Charlie** had the highest follower count, with **45 followers**, followed by **Harris (42)**.
- **Archie, Harris, and Harrison** shared the highest average likes per post at **21.00**. Each had one post, so this result should be interpreted alongside posting volume.
- Five users had not published any posts: **Cameron, George, Jamie, Joshua, and Ollie**.

### Content and Engagement

- **Post 42 ("Mirror:")** was the most-liked post, receiving **24 likes**.
- When engagement is defined as likes plus comments, the highest-performing post identified for an individual user was **Liam's Post 42**, with **28 total interactions** (24 likes and 4 comments).
- The highest average engagement by hashtag was associated with **#runforunity (20.83 across 12 posts)**, followed by **#sunnyday (20.70 across 10 posts)**.
- The most-liked comment received **7 likes**.

### Hashtag Insights

- **#beautiful** was the most frequently used hashtag, appearing in **21 posts**.
- **#festivesale** and **#socialmedia** followed with **19 uses each**.
- **#festivesale** had the highest follower count among hashtags, with **4 followers**, followed by **#studentlivesmatter (3)**.
- **#GOGREEN** had no recorded post usage.

### Additional Observations

- No user had liked every post in the database.
- No post had more bookmarks than likes in the corresponding comparison.
- The query identifying users who both liked and bookmarked the same post returned matching user–post pairs, demonstrating how these two activity tables can be joined at both user and post level.
- The login sequence analysis used `LAG()` and `LEAD()` to compare consecutive login timestamps. The recorded timestamps are tightly clustered, with many intervals of zero or one second; they are not suitable for drawing conclusions about realistic user login behavior.

## Data Quality and Limitations

- The hashtag name **#followme** appears in two separate hashtag records, with **18** and **9** post usages. These are separate `hashtag_id` values in the source data, so the results should not be combined without a deliberate data-cleaning rule.
- The dataset contains inconsistent text formatting, capitalization, and whitespace in some hashtag names, captions, and location values.
- The login timestamps are highly concentrated within a very short period. Login interval results are therefore useful mainly as a demonstration of SQL window functions, not as behavioral evidence.
- The database is a small sample dataset. Findings are descriptive of the available records and cannot be generalized to actual social media platforms or user populations.

## SQL Techniques Demonstrated

The analysis applies:

- Multi-table `JOIN` operations, including `LEFT JOIN`
- Aggregations with `COUNT()`, `SUM()`, and `AVG()`
- Subqueries and Common Table Expressions (`CTEs`)
- Conditional null handling with `COALESCE()`
- Window functions including `AVG() OVER()`, `ROW_NUMBER()`, `RANK()`, `LAG()`, and `LEAD()`
- Date/time calculations with `TIMESTAMPDIFF()`
- Filtering grouped and derived results with `HAVING` and outer queries

---

*Note: Results reflect the query outputs and dataset version included in this repository. They may change if the underlying records or query logic are updated.*