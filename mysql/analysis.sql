-- 1. Company Impact
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs_cleaned
GROUP BY company
ORDER BY 2 DESC;

-- 2. Country/Industry Impact
SELECT country, SUM(total_laid_off) AS total_layoffs
FROM layoffs_cleaned
GROUP BY country
ORDER BY 2 DESC;

SELECT industry, SUM(total_laid_off) total_layoffs
FROM layoffs_cleaned
GROUP BY industry
ORDER BY 2 DESC;

-- 3. Time Trends
SELECT YEAR(`date`), SUM(total_laid_off) AS total_layoffs
FROM layoffs_cleaned
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

SELECT `date`,  SUM(total_laid_off) total_layoffs
FROM layoffs_cleaned
GROUP BY `date`
ORDER BY 2 DESC;

SELECT SUBSTRING(`date`, 1,7) AS `Month`,  SUM(total_laid_off) total_layoffs
FROM layoffs_cleaned
GROUP BY SUBSTRING(`date`, 1, 7)
ORDER BY 2 DESC;

SELECT DATE_FORMAT(`date`, '%Y-%m') AS month, SUM(total_laid_off) AS total_layoffs
FROM layoffs_cleaned
GROUP BY month
ORDER BY 2 DESC;

SELECT 
YEAR(date) AS year,
QUARTER(date) AS quarter,
SUM(total_laid_off) AS total_layoffs
FROM layoffs_cleaned
GROUP BY YEAR(date), QUARTER(date)
ORDER BY year, quarter;

-- 4. Funding stage analysis
SELECT stage, SUM(total_laid_off)
FROM layoffs_cleaned
GROUP BY stage
ORDER BY 2 DESC;

-- 5. Funding vs Layoffs Relationship
WITH ranked_funds AS
(
SELECT company, funds_raised_millions,
SUM(total_laid_off) AS total_layoffs,
DENSE_RANK() OVER(ORDER BY funds_raised_millions DESC) AS funds_rank,
DENSE_RANK() OVER(ORDER BY SUM(total_laid_off) DESC) AS layoffs_rank
FROM layoffs_cleaned
GROUP BY company, funds_raised_millions
)
SELECT *,
	(CAST(layoffs_rank AS SIGNED)-CAST(funds_rank AS SIGNED)) AS rank_gap
FROM ranked_funds
ORDER BY funds_rank;

-- 6.Startup Stage Behaviour
-- total layoff by stage
WITH stage_summary AS
(
SELECT company,
stage,
funds_raised_millions,
SUM(total_laid_off) AS total_layoffs,
SUM(SUM(total_laid_off)) OVER(PARTITION BY stage) AS total_stage_layoffs,
DENSE_RANK() OVER(PARTITION BY stage ORDER BY SUM(total_laid_off) DESC) AS layoffs_rank
FROM layoffs_cleaned
WHERE stage IN('Series D', 'Series E', 'Series F', 'Series G', 'Series H', 'Series I', 'Series J')
GROUP BY company, stage, funds_raised_millions
)
SELECT *,
ROUND(total_layoffs / total_stage_layoffs * 100, 2) AS percentage_stage_layoffs
FROM stage_summary
ORDER BY stage DESC, total_layoffs DESC;

-- stage progression and summary
SELECT
stage,
COUNT(DISTINCT company)  AS num_of_companies,
SUM(total_laid_off) AS total_stage_layoffs,
DENSE_RANK() OVER(ORDER BY SUM(total_laid_off) DESC) AS total_stage_layoffs_rank,
AVG(total_laid_off) AS avg_layoffs_per_company,
ROUND(SUM(total_laid_off) / COUNT(DISTINCT company)) AS layoffs_per_company
FROM layoffs_cleaned
WHERE stage IN ('Series D', 'Series E', 'Series F', 'Series G', 'Series H', 'Series I', 'Series J')
GROUP BY stage
ORDER BY FIELD (stage, 'Series D', 'Series E', 'Series F', 'Series G', 'Series H', 'Series I', 'Series J');

-- 7. Funding Buckets
SELECT company,
SUM(total_laid_off) AS total_layoffs,
SUM(funds_raised_millions) AS total_funds_raised
FROM layoffs_cleaned
GROUP BY company
ORDER BY total_layoffs DESC;

WITH funds_bucket AS
(SELECT 
CASE
	WHEN funds_raised_millions <= 100 THEN '<100M'
    WHEN funds_raised_millions BETWEEN 101 AND 1000 THEN '101M-1000M'
    WHEN funds_raised_millions BETWEEN 1001 AND 5000 THEN '1001M-5000M'
    WHEN funds_raised_millions BETWEEN 5001 AND 10000 THEN '5001M-10000M'
    WHEN funds_raised_millions >10000 THEN '>10000M'
END AS funding_bucket,
COUNT(DISTINCT company) AS num_companies, 
SUM(total_laid_off) AS total_layoffs,
SUM(funds_raised_millions) AS total_funds_raised,
ROUND(AVG(total_laid_off), 2) AS avg_layoffs_per_company,
ROUND(SUM(total_laid_off) / NULLIF(SUM(funds_raised_millions), 0), 2) AS layoffs_per_100M
FROM layoffs_cleaned
GROUP BY funding_bucket
)
SELECT *,
DENSE_RANK() OVER(ORDER BY total_layoffs DESC) AS layoffs_rank,
DENSE_RANK() OVER(ORDER BY total_funds_raised DESC) AS total_funds_rank
FROM funds_bucket
ORDER BY layoffs_rank, total_funds_rank;

-- 8. Cumulative Layoffs Trend
SELECT 
DATE_FORMAT(date, '%Y-%m') AS month,
SUM(total_laid_off) AS monthly_layoffs,
SUM(SUM(total_laid_off)) OVER(ORDER BY DATE_FORMAT(date, '%Y-%m')) AS cumulative_layoffs
FROM layoffs_cleaned
GROUP BY month
ORDER BY month;


