/* ---------------------------------------------------------------------------
  COVID19_Clinical_Trials_Analysis.sql
  Full MySQL script — Cleaning, transformation, analysis, and export
  Author: Anonymous
  Project: COVID-19 Clinical Trials Dashboard
--------------------------------------------------------------------------- */

-- Create and select database
CREATE DATABASE IF NOT EXISTS covid_trials;
USE covid_trials;

-- Drop existing table if any
DROP TABLE IF EXISTS covid_trials_raw;

-- Step 1: Import raw data into MySQL (CSV import step to be done manually)
CREATE TABLE covid_trials_raw (
  Rank INT,
  `NCT Number` VARCHAR(50),
  Title TEXT,
  Acronym VARCHAR(255),
  Status VARCHAR(100),
  `Study Results` VARCHAR(100),
  Conditions TEXT,
  Interventions TEXT,
  `Outcome Measures` TEXT,
  `Sponsor/Collaborators` TEXT,
  `Study Type` VARCHAR(100),
  Phase VARCHAR(50),
  `Start Date` VARCHAR(50),
  `Completion Date` VARCHAR(50),
  `Primary Completion Date` VARCHAR(50),
  Country VARCHAR(100),
  Location TEXT,
  `Last Update Posted` VARCHAR(50)
);

-- Step 2: Create Clean Table
CREATE TABLE covid_trials_clean AS
SELECT
  TRIM(`NCT Number`) AS nct_number,
  TRIM(Title) AS title,
  CASE
    WHEN LOWER(Status) LIKE '%recruit%' THEN 'Recruiting'
    WHEN LOWER(Status) LIKE '%complete%' THEN 'Completed'
    WHEN LOWER(Status) LIKE '%terminate%' THEN 'Terminated'
    WHEN LOWER(Status) LIKE '%withdraw%' THEN 'Withdrawn'
    ELSE Status
  END AS status,
  TRIM(Phase) AS phase,
  TRIM(`Study Type`) AS study_type,
  STR_TO_DATE(`Start Date`, '%Y-%m-%d') AS start_date,
  STR_TO_DATE(`Completion Date`, '%Y-%m-%d') AS completion_date,
  TRIM(Country) AS country,
  TRIM(`Sponsor/Collaborators`) AS sponsor,
  TRIM(Conditions) AS conditions,
  TRIM(Interventions) AS interventions
FROM covid_trials_raw;

-- Step 3: Add Duration Column
ALTER TABLE covid_trials_clean ADD COLUMN duration_days INT;
UPDATE covid_trials_clean
SET duration_days = DATEDIFF(completion_date, start_date)
WHERE start_date IS NOT NULL AND completion_date IS NOT NULL;

-- Step 4: Summary Queries
SELECT COUNT(*) AS total_trials FROM covid_trials_clean;

SELECT status, COUNT(*) AS trial_count
FROM covid_trials_clean
GROUP BY status
ORDER BY trial_count DESC;

SELECT phase, COUNT(*) AS phase_count
FROM covid_trials_clean
GROUP BY phase;

SELECT country, COUNT(*) AS trial_count
FROM covid_trials_clean
GROUP BY country
ORDER BY trial_count DESC
LIMIT 10;

SELECT ROUND(AVG(duration_days), 1) AS avg_trial_duration
FROM covid_trials_clean
WHERE duration_days IS NOT NULL;

-- Step 5: Export cleaned data
SELECT *
INTO OUTFILE '/var/lib/mysql-files/COVID19_Clinical_Trials_Cleaned.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
FROM covid_trials_clean;

-- End of SQL Script
