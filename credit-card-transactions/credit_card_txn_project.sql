/*
CREDIT CARD TRANSCATIONS PROJECT

Dataset Source - https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
*/

USE projects;

SELECT * FROM credit_card_transactions;

# Checking the raw data format for transaction_date
SELECT DISTINCT
    transaction_date
FROM
    credit_card_transactions
LIMIT 10;

# Testing
SELECT 
    transaction_date,
    STR_TO_DATE(transaction_date, '%d-%b-%y') AS converted_date
FROM
    credit_card_transactions
LIMIT 10;

# Converting the datatype to date
-- Step 1: Add a new DATE column
ALTER TABLE credit_card_transactions 
ADD COLUMN transaction_date_new DATE;

-- Step 2: Updating using the correct format
UPDATE credit_card_transactions 
SET 
    transaction_date_new = STR_TO_DATE(transaction_date, '%d-%b-%y');

-- Step 3: Drop the old column
ALTER TABLE credit_card_transactions 
DROP COLUMN transaction_date;

-- Step 4: Rename the new column
ALTER TABLE credit_card_transactions 
CHANGE transaction_date_new transaction_date DATE;


# Basic data exploration
SELECT * FROM credit_card_transactions;

SELECT 
    MIN(transaction_date), MAX(transaction_date)
FROM
    credit_card_transactions;
    
SELECT 
    MIN(amount), MAX(amount)
FROM
    credit_card_transactions;

SELECT DISTINCT
    card_type
FROM
    credit_card_transactions;

SELECT DISTINCT
    exp_type
FROM
    credit_card_transactions;

SELECT 
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amountt
FROM
    credit_card_transactions;

SELECT 
    city, COUNT(*) AS transaction_count
FROM
    credit_card_transactions
GROUP BY city
ORDER BY transaction_count DESC;

SELECT 
    exp_type, COUNT(*) AS count
FROM
    credit_card_transactions
GROUP BY exp_type
ORDER BY count DESC;


# Gender based insights
SELECT 
    gender, 
    COUNT(*) AS transactions,
    SUM(amount) AS total_spent,
    AVG(amount) AS avg_spent
FROM
    credit_card_transactions
GROUP BY gender;


# Card type insights
SELECT 
    card_type,
    COUNT(*) AS transactions,
    SUM(amount) AS total_spent,
    AVG(amount) AS avg_spent
FROM
    credit_card_transactions
GROUP BY card_type;


# Time based analysis
SELECT 
    YEAR(transaction_date) AS year,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount_spent,
    AVG(amount) AS avg_amount_spent
FROM
    credit_card_transactions
GROUP BY year
ORDER BY year;

SELECT 
    DATE_FORMAT(transaction_date, '%y-%b') AS month,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount_spent,
    AVG(amount) AS avg_amount_spent
FROM
    credit_card_transactions
GROUP BY month
ORDER BY month;


# Top 10 transactions
SELECT 
    *
FROM
    credit_card_transactions
ORDER BY amount DESC
LIMIT 10;


-- ------------- --


# Top 5 highest spending cities with their percentage of contribution
SELECT 
    city, 
    SUM(amount) AS city_total_spent,
    ROUND(SUM(amount)/(select sum(amount) from credit_card_transactions) * 100, 2) as contribution_percent
FROM
    credit_card_transactions
GROUP BY city
ORDER BY city_total_spent DESC
LIMIT 5;


# Highest spent month for each card type
WITH ct_amt AS
(SELECT 
	card_type,
    EXTRACT(year_month FROM transaction_date) AS year_mon,
    SUM(amount) AS total_spend
FROM credit_card_transactions
GROUP BY card_type, year_mon)
SELECT *
FROM 
(SELECT *, RANK() OVER(PARTITION BY card_type ORDER BY total_spend DESC) as rn 
FROM ct_amt) a
WHERE rn = 1;


# Transaction details for each card type when it reaches a cumulative of 1000000 total spends
WITH total_spend AS
(SELECT 
	*,
	SUM(amount) OVER(PARTITION BY card_type ORDER BY transaction_date, transaction_id) as total
FROM credit_card_transactions)
SELECT *
FROM (SELECT *, RANK() OVER(PARTITION BY card_type ORDER BY total) as rn FROM total_spend WHERE total >= 1000000) a 
WHERE rn = 1; 


# City with lowest percentage spending for Gold card type
WITH city_card_amt AS (
SELECT city, card_type, 
	SUM(amount) AS amount,
	SUM(CASE WHEN card_type='Gold' THEN amount END) AS gold_amount
FROM credit_card_transactions
GROUP BY city,card_type
)
SELECT
	city, SUM(gold_amount)/SUM(amount) AS gold_ratio
FROM city_card_amt
GROUP BY city
HAVING COUNT(gold_amount) > 0 
ORDER BY gold_ratio
LIMIT 1;


# Highest & lowest expense type for each city
WITH city_exp_amt AS (
SELECT city, exp_type, SUM(amount) as total_amt
FROM credit_card_transactions
GROUP BY city, exp_type)
SELECT city, 
max(CASE when rn_asc = 1 THEN exp_type END) AS lowest_exp, 
min(CASE when rn_desc = 1 THEN exp_type END) AS highest_exp
FROM
(SELECT *,
RANK() OVER(partition by city order by total_amt DESC) rn_desc,
RANK() OVER(partition by city order by total_amt ASC) rn_asc
FROM city_exp_amt) a
GROUP BY city
;


# Percentage contribution of spends by female for each expense type
SELECT 
    exp_type,
    ROUND(SUM(CASE WHEN gender = 'F' THEN amount ELSE 0 END) / SUM(amount)* 100, 2) AS percentage_female_contribution
FROM
    credit_card_transactions
GROUP BY exp_type
ORDER BY percentage_female_contribution DESC;


# Card & expense type combination with highest month over month growth in Jan-2014
WITH ce_total AS
(SELECT 
	card_type, 
    exp_type, extract(year_month FROM transaction_date) AS y_m, sum(amount) AS total 
FROM credit_card_transactions 
GROUP BY card_type, exp_type, y_m),
lag_total AS
(SELECT 
	*, 
    LAG(total) OVER(PARTITION BY card_type, exp_type ORDER BY y_m) AS prev_total 
FROM ce_total)
SELECT 
	card_type, exp_type,
    (total-prev_total)/prev_total AS mom_growth 
FROM lag_total 
WHERE y_m = "201401" 
ORDER BY mom_growth DESC 
LIMIT 1;


# City with highest total spend to total transactions ratio during weekends
SELECT city, SUM(amount)/COUNT(1) as ratio
FROM credit_card_transactions
WHERE weekday(transaction_date) in (5,6)
GROUP BY city
ORDER BY ratio DESC
LIMIT 1;


# City that tool least number of days to reach its 500th transaction 
WITH cte as (
SELECT *, 
row_number() OVER(partition by city order by transaction_date) AS rn
FROM credit_card_transactions
)
SELECT city, datediff(MAX(transaction_date), MIN(transaction_date)) AS no_days  
FROM cte 
WHERE rn=1 OR rn=500
GROUP BY city
HAVING COUNT(1) = 2
ORDER BY no_days
LIMIT 1;

