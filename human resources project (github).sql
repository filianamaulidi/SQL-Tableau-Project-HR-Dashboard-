create database humanresources;

-- create table
CREATE TABLE hr (
    id VARCHAR(15),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birthdate VARCHAR(20),
    gender VARCHAR(50),
    race VARCHAR(50),
    department VARCHAR(50),
    jobtitle VARCHAR(50),
    location VARCHAR(50),
    hire_date VARCHAR(50),
    termdate VARCHAR(30),
    location_city VARCHAR(50),
    location_sate VARCHAR(50)
);
drop table hr;

-- modify column name
alter table hr change column location_sate location_state varchar(50);

-- upload data
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/human resources.csv'
into table hr
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 lines;
select * from hr;
drop table hr;

SET sql_safe_updates = 0;

-- modify date formatting in birthdate column
UPDATE hr
SET birthdate = CASE
	WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;
ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

-- modify date formatting in hire_date column
UPDATE hr
SET hire_date = CASE
	WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;
ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- modify date formatting in termdate column
UPDATE hr
SET termdate = IF(termdate IS NOT NULL AND termdate !='', date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
WHERE TRUE;
SELECT termdate FROM hr;
SET sql_mode = 'ALLOW_INVALID_DATES';
ALTER TABLE hr
MODIFY COLUMN termdate DATE;

-- add column age
alter table hr add column age int;
UPDATE hr 
SET age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE());

-- outlier (max min)
SELECT MIN(age) AS youngest, MAX(age) AS oldest
FROM hr;-- ada nilai negatif
SELECT COUNT(*)
FROM hr
WHERE age < 18;
SELECT COUNT(*) FROM hr WHERE termdate > CURDATE();
SELECT COUNT(*)
FROM hr
WHERE termdate = '0000-00-00';


-- Data Analysis
-- 1. What is the gender breakdown of employees in the company?
SELECT 
    gender, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY gender;

-- 2. What is the race ethnicity breakdown of employees in the company?
SELECT 
    race, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY race
ORDER BY COUNT(*) DESC;

-- 3. What is the age distribution of employees in the company?
SELECT 
    MIN(age) youngest, MAX(age) oldest
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00';

SELECT 
    CASE
        WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY age_group
ORDER BY age_group;

SELECT 
    CASE
        WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    gender,
    COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY age_group , gender
ORDER BY age_group , gender;

-- 4. How many employees work at headquarters versus remote locations?
SELECT 
    location, COUNT(location) AS count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location;

-- 5. What is the average length of employment for employees who have been terminated?
SELECT 
    ROUND(AVG(DATEDIFF(termdate, hire_date)) / 365, 0) AS avg_length_employment
FROM hr
WHERE
    termdate <= CURDATE()
        AND termdate <> '0000-00-00'
        AND age >= 18; 

-- 6. How does the gender distribution vary across departments and job titles?
SELECT 
    department, gender, COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY department , gender
ORDER BY department;

-- 7. What is the distribution of job titles in the company?
SELECT 
    jobtitle, COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- 8. Which department has the highest turnover rate?
SELECT 
    department,
    total_count,
    terminated_count,
    terminated_count / total_count AS termination_rate
FROM (
    SELECT department, 
    COUNT(*) AS total_count, 
    SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminated_count
    FROM hr
    WHERE age >= 18
    GROUP BY department) AS subquery
ORDER BY termination_rate DESC;

-- 9. What is the distribution of employees across the locations by city and state?
SELECT 
    location_state, COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY location_state
ORDER BY count DESC;

-- 10. How has the company's employee count changed over time based on hire and term dates?
SELECT 
    year,
    hires,
    terminations,
    hires - terminations AS net_change,
    ROUND((hires - terminations) / hires * 100, 2) AS net_change_percent
FROM (
    SELECT 
        YEAR(hire_date) AS year,
		COUNT(*) AS hires,
		SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM hr
    WHERE
        age >= 18
    GROUP BY YEAR(hire_date)) AS subqery
ORDER BY year ASC;

-- 11. What is the tenure distribution for each department? (how long employees stay in each department before they quit or fired or something of the sort)?
SELECT 
    department,
    ROUND(AVG(DATEDIFF(termdate, hire_date) / 365), 0) AS avg_tenure
FROM
    hr
WHERE
    termdate <= CURDATE() AND termdate <> '0000-00-00' AND age >= 18
GROUP BY department;