SELECT 
	country As Country,
	YEAR(date) AS Year,
	MONTH(date) AS Month,
	SUM(daily_vaccinations) AS Num_vaccinations
FROM 
	country_vaccinations$
WHERE 
	country IN ('United States', 'Peru', 'Canada', 'Mexico')
GROUP BY 
	country, YEAR(date), MONTH(date)
ORDER BY country, YEAR(date), MONTH(date)

--STORE MONTHLY-LEVEL VACCINATIONS IN A TEMP TABLE

CREATE TABLE #Monthly_Vaccinations(
Country varchar(50),
Year int,
Month int,
num_vaccinations float)

INSERT INTO #Monthly_Vaccinations
SELECT 
	country As Country,
	YEAR(date) AS Year,
	MONTH(date) AS Month,
	SUM(daily_vaccinations) AS Num_vaccinations
FROM 
	country_vaccinations$
WHERE 
	country IN ('United States', 'Peru', 'Canada', 'Mexico')
GROUP BY 
	country, 
  YEAR(date), 
  MONTH(date)
ORDER BY 
  country, 
  YEAR(date), 
  MONTH(date)

--To compute the 3-month moving average, we need to:

--1. Find the vaccination values for the current month and the two preceding months.
--2. Find the average number of vaccinations within the 3 months for each row.

SELECT *,
  ROUND(AVG(num_vaccinations) OVER(PARTITION BY Country ORDER BY Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ),0) AS moving_average
FROM #Monthly_Vaccinations

--WHAT IS THE PERCENT CHANGE IN MONTHLY VACCINATIONS IN EACH COUNTRY?
--To find the percent change in monthly vaccinations, we need to:

--1. Find the number of vaccinations in the previous month for each row
--2. Compute the percent change in vaccinations for each row given the current and previous vaccination values

SELECT *,
	ISNULL(LAG(num_vaccinations) OVER(PARTITION BY Country ORDER BY Month),0) AS prev_vaccination
FROM #Monthly_Vaccinations

--------------------------------------------------------------------------------------------------------------------------------------------

WITH prev_count AS(
SELECT *,
	ISNULL(LAG(num_vaccinations) OVER(PARTITION BY Country ORDER BY Month),0) AS prev_vaccination
FROM #Monthly_Vaccinations)

SELECT *,
	ROUND((num_vaccinations - prev_vaccination)/ num_vaccinations *100,2) AS pct_change
FROM prev_count

--WHICH MONTHS REGISTERED THE LOWEST VACCINATIONS FOR EACH COUNTRY?
-- 1. Rank the records in terms of the number of vaccinations (lowest to highest)
--2. Select the rows that have the highest rank (i.e. rank=1)

SELECT *,
	RANK() OVER(PARTITION BY Country ORDER BY num_vaccinations) as rk
FROM #Monthly_Vaccinations

--------------------------------------------------------------------------------------------------------------

-- CTE FOR STORING RANKED DATA
WITH vaccinations_ranked AS(
SELECT *,
	RANK() OVER(PARTITION BY Country ORDER BY num_vaccinations) as rk
FROM 
	#Monthly_Vaccinations)

SELECT Country,
	Year,
	Month,
	num_vaccinations
FROM 
	vaccinations_ranked
WHERE 
	-- select only the highest ranking records
	rk = 1

---------------------------------------------------------------------------------------------------------------
--FIND THE 3 WORST MONTHS


WITH vaccinations_ranked AS(
SELECT *,
	RANK() OVER(PARTITION BY Country ORDER BY num_vaccinations) as rk
FROM 
	#Monthly_Vaccinations)

SELECT Country,
	Year,
	Month,
	num_vaccinations
FROM 
	vaccinations_ranked
WHERE 
	-- select only the 3 highest ranking records 
	rk <=3

-------------------------------------------------------------------------------------------------------------------------

--WHICH COUNTRY IS CURRENTLY THE MOST SUCCESSFUL IN ADMINISTERING VACCINES?

--To find the country with the best vaccination to population ratio, we need to:

--1. Find the total vaccines (cumulative) administered in each country

SELECT 
	country,
	Month,
	num_vaccinations,
 	-- find the running total vaccinations
	SUM(num_vaccinations) OVER(PARTITION BY country ORDER BY Month) AS total_vaccinations
FROM 
	#Monthly_Vaccinations

--2. Find the population of each country

CREATE TABLE Population3(
  Country varchar(50),
  Population int)

INSERT INTO Population3 
VALUES 
	('United States', 234455233),
	('Peru', 5453554),
	('Canada', 235765),
	('Mexico', 2345566);
SELECT *
FROM 
  Population3

--3. Calculate the vaccination to population ratio for each record
-- CTE for storing running total 

WITH running_total AS(
SELECT 
	country,
	Year,
	Month,
	num_vaccinations,
	-- find the running total vaccinations
	SUM(num_vaccinations) OVER(PARTITION BY country ORDER BY Month) AS total_vaccinations
FROM 
	#Monthly_Vaccinations)

SELECT R.Country,
	R.Year,
	R.Month,
	R.num_vaccinations,
	P.Population,
	-- compute vaccinations per 100k capira
	ROUND((R.num_vaccinations/P.Population)*100000,0) AS Vaccinations_per_100k_capita
FROM 
	running_total R
INNER JOIN Population P
	ON R.Country = p.Country

--4. Keep only the records from the latest month
-- CTE for storing running total

WITH running_total AS(
SELECT 
	country,
	Year,
	Month,
	num_vaccinations,
	-- find the running total vaccinations
	SUM(num_vaccinations) OVER(PARTITION BY country ORDER BY Month) AS total_vaccinations
FROM 
	#Monthly_Vaccinations),

-- CTE for storing vaccinations per capita
vaccinations_per_capita AS (
SELECT R.Country,
	R.Year,
	R.Month,
	R.num_vaccinations,
	P.Population,
	-- compute vaccinations per 100k capita
	ROUND((R.num_vaccinations/P.Population)*100000,0) AS Vaccinations_per_100k_capita
FROM 
	running_total R
INNER JOIN Population P
	ON R.Country = p.Country)

SELECT Country, 
	Year,
	Month,
	Vaccinations_per_100k_capita
FROM 
	vaccinations_per_capita 
WHERE 
	-- Select records from the latest month
	Month = 
	(SELECT MAX(Month)
	FROM #Monthly_Vaccinations)
ORDER BY 
	Vaccinations_per_100k_capita DESC
