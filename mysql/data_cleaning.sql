-- 1. Create Database
CREATE DATABASE layoffs_analysis;
USE layoffs_analysis;

-- Import CSV as layoffs_raw using MySQL Workbench import wizard

-- 2. Create Staging Table
CREATE TABLE layoffs_staging
LIKE layoffs_raw;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs_raw;

-- 3. Remove Duplicates
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicates AS
(
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicates
WHERE row_num != 1;

-- 3.1 Create a new staging table with the row_num column
CREATE TABLE `layoffs_cleaned` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_cleaned
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_cleaned
WHERE row_num != 1;

-- Delete the duplicates
DELETE  
FROM layoffs_cleaned
WHERE row_num != 1;

-- 4. Standardize the Data
-- 4.1 Standardize the data of column 1
SELECT company, TRIM(company)
FROM layoffs_cleaned;

UPDATE layoffs_cleaned
SET company = TRIM(company);

-- 4.2 Standardize the data of column 2
SELECT DISTINCT location
FROM layoffs_cleaned;
-- No faults found

-- 4.3 Standardize the data of column 3
SELECT industry
FROM layoffs_cleaned;

SELECT industry
FROM layoffs_cleaned
WHERE industry LIKE "Crypto%";

UPDATE layoffs_cleaned
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

-- 4.4 Standardize the data of column 5
ALTER TABLE layoffs_cleaned
MODIFY COLUMN percentage_laid_off DECIMAL(10,2);

-- 4.5 Change the data type of the sixth column
SELECT `date`, STR_TO_DATE(`date`, "%m/%d/%Y")
FROM layoffs_cleaned;

UPDATE layoffs_cleaned
SET `date` = STR_TO_DATE(`date`, "%m/%d/%Y");

ALTER TABLE layoffs_cleaned
MODIFY COLUMN `date` DATE;

-- 4.6 Standardize the data of column 8
SELECT DISTINCT country
FROM layoffs_cleaned
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING "." FROM country)
FROM layoffs_cleaned
ORDER BY 1;

UPDATE layoffs_cleaned
SET country = TRIM(TRAILING "." FROM country);

-- 5. Re-populate the data wherever possible
SELECT company, industry
FROM layoffs_cleaned
WHERE industry IS null OR industry ="";

UPDATE layoffs_cleaned
SET industry = NULL
WHERE industry = "";

SELECT *
FROM layoffs_cleaned
WHERE company REGEXP '^Airbnb|^Bally';

SELECT *
FROM layoffs_cleaned AS t1
JOIN layoffs_cleaned AS t2
	ON t1.company = t2.company
WHERE t1.industry IS NOT NULL
AND t2.industry IS NULL;

UPDATE layoffs_cleaned t1
JOIN layoffs_cleaned t2
	ON t1.company = t2.company
SET t2.industry = t1.industry
WHERE t1.industry IS NOT NULL
AND t2.industry IS NULL;

-- 6. Remove NULL or Blank Values
SELECT company, total_laid_off, percentage_laid_off
FROM layoffs_cleaned
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_cleaned
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- 7. Remove unnecessary columns
SELECT row_num
FROM layoffs_cleaned;

ALTER TABLE layoffs_cleaned
DROP COLUMN row_num;

-- 8. Final Cleaned Dataset
SELECT COUNT(*) AS cleaned_rows
FROM layoffs_cleaned;

