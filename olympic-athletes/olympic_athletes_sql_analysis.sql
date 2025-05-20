/*
OLYMPIC ATHLETES SQL ANALYSIS

Dataset Source - https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results

The data contains 120 years of olympics history. There are 2 daatsets 
1- athletes : it has information about all the players participated in olympics
2- athlete_events : it has information about all the events happened over the year.(athlete id refers to the id column in athlete table)
*/


# Primary Data Exploration

SELECT * FROM athletes;

-- Check table structure
DESCRIBE athletes;

-- Row count
SELECT COUNT(*) FROM athletes;

-- Count of distinct names
SELECT COUNT(DISTINCT name) AS unique_names FROM athletes;

-- Null/missing value checks
SELECT
  SUM(CASE WHEN team IS NULL OR team = '' THEN 1 ELSE 0 END) AS missing_team,
  SUM(CASE WHEN height IS NULL OR height = '' THEN 1 ELSE 0 END) AS missing_height,
  SUM(CASE WHEN weight IS NULL OR weight = '' THEN 1 ELSE 0 END) AS missing_weight
FROM athletes;

-- Cleaning spaces or empty strings
UPDATE athletes
SET height = NULL
WHERE TRIM(height) = '' OR height NOT REGEXP '^[0-9]+$';

UPDATE athletes
SET weight = NULL
WHERE TRIM(weight) = '' OR weight NOT REGEXP '^[0-9]+$';

-- Convert height to INT
ALTER TABLE athletes
MODIFY COLUMN height INT;

-- Convert weight to INT
ALTER TABLE athletes
MODIFY COLUMN weight INT;

-- Gender distribution
SELECT sex, COUNT(*) AS count FROM athletes GROUP BY sex;

-- Average height and weight by gender
SELECT sex,
       AVG(height) AS avg_height,
       AVG(weight) AS avg_weight
FROM athletes
GROUP BY sex;

-- Top teams by number of athletes
SELECT team, COUNT(*) AS count
FROM athletes
GROUP BY team
ORDER BY count DESC
LIMIT 10;


SELECT * FROM athlete_events;

-- Check table structure
DESCRIBE athlete_events;

-- Row count
SELECT COUNT(*) FROM athlete_events;

-- Count of distinct athletes
SELECT COUNT(DISTINCT athlete_id) AS distinct_athletes FROM athlete_events;

-- Null/missing value checks (NULLs need to be handled manually in CSV imports)
SELECT
  SUM(CASE WHEN games IS NULL OR games = '' THEN 1 ELSE 0 END) AS missing_games,
  SUM(CASE WHEN sport IS NULL OR sport = '' THEN 1 ELSE 0 END) AS missing_sport,
  SUM(CASE WHEN event IS NULL OR event = '' THEN 1 ELSE 0 END) AS missing_event,
  SUM(CASE WHEN Medal IS NULL OR Medal = '' THEN 1 ELSE 0 END) AS missing_medal
FROM athlete_events;

-- Medal distribution
SELECT Medal, COUNT(*) AS count FROM athlete_events
GROUP BY Medal;

-- Participation by year and season
SELECT Year, Season, COUNT(*) AS total_participations
FROM athlete_events
GROUP BY Year, Season
ORDER BY Year;

-- Top sports by athlete count
SELECT Sport, COUNT(DISTINCT athlete_id) AS athlete_count
FROM athlete_events
GROUP BY Sport
ORDER BY athlete_count DESC
LIMIT 10;


# Advanced SQL Analysis

# Team that wan maximum gold medals over the years

SELECT 
    a.team,
    SUM(CASE
        WHEN e.medal = 'Gold' THEN 1
        ELSE 0
    END) AS no_gold
FROM
    athletes a
        LEFT JOIN
    athlete_events e ON a.id = e.athlete_id
GROUP BY a.team
ORDER BY no_gold DESC
LIMIT 1
;


# Total silver medals won by a team and the year of there maximum silver

WITH cte_silver AS
(SELECT
	a.team, e.year, 
	count(DISTINCT e.event) AS silver_medals,
	rank() over(PARTITION BY a.team ORDER BY count(DISTINCT e.event) DESC) AS rn
FROM
	athletes a
		INNER JOIN 
	athlete_events e ON a.id = e.athlete_id
WHERE
	e.medal = "Silver"
GROUP BY a.team, e.year)
SELECT
	team, sum(silver_medals) AS total_silver_medals,
	max(case when rn=1 then year end) AS year_of_max_silver
FROM cte_silver
GROUP BY team
;


# Player with maximum gold medals and only gold 

WITH cte AS (
SELECT 
    a.name, e.medal
FROM
    athletes a
        INNER JOIN
    athlete_events e ON a.id = e.athlete_id
)
SELECT
	name, count(distinct medal) AS total_gold
FROM cte 
GROUP BY name
HAVING total_gold NOT IN ("Silver", "Bronze", "NA")
ORDER BY total_gold DESC
;


# Players with maximum gold medal each year

WITH cte AS (
SELECT 
    e.year, a.name, COUNT(1) AS total_golds
FROM
    athletes a
        INNER JOIN
    athlete_events e ON a.id = e.athlete_id
WHERE
    e.medal = 'Gold'
GROUP BY e.year , a.name)
SELECT year, total_golds, group_concat(name) as players
FROM
	(SELECT *, rank() over(PARTITION BY year ORDER BY total_golds DESC) AS rn
    FROM cte) a WHERE rn=1
GROUP BY year, total_golds
;


# Year and event of India's first gold, silver or bronze medal 

WITH cte AS(
SELECT 
	e.medal, e.year, e.event,
	rank() over(partition by e.medal order by e.year) as rn
FROM
	athlete_events e
		INNER JOIN
	athletes a ON e.athlete_id = a.id
WHERE 
	team = "India" AND medal <> "NA" 
GROUP BY e.medal, e.year, e.event)
SELECT
	medal, year, event
FROM cte
WHERE rn=1
;


# First player to win gold medal in both summer & winter olympics

SELECT 
    a.name
FROM
    athlete_events e
        INNER JOIN
    athletes a ON e.athlete_id = a.id
WHERE
    e.medal = 'gold'
GROUP BY a.name
HAVING COUNT(DISTINCT e.season) = 2
;


# Players who gold gold, silver & bronze medal in single olympics

SELECT 
    e.year, a.name
FROM
    athlete_events e
        INNER JOIN
    athletes a ON e.athlete_id = a.id
WHERE
    medal <> 'NA'
GROUP BY e.year , a.name
HAVING COUNT(DISTINCT e.medal) = 3
;


# Players with gold medals in consecutive 3 summer olympics after 2000

WITH cte AS(
SELECT 
    a.name, e.year, e.event
FROM
    athlete_events e
        INNER JOIN
    athletes a ON e.athlete_id = a.id
WHERE
    e.year > 2000 AND e.season = 'Summer'
        AND e.medal = 'Gold'
GROUP BY a.name , e.year , e.event)
SELECT * 
FROM 
	(SELECT *,
		lag(year, 1) over(PARTITION BY name, event ORDER BY year) AS prev_year,
        lead(year, 1) OVER(PARTITION BY name, event ORDER BY year) AS next_year
	FROM cte) a
WHERE 
	year = prev_year+4 AND year=next_year-4
;

