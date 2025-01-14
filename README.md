# HR Employee Distribution Dashboard
Tableau project preview: 
![HR (1)](https://github.com/user-attachments/assets/58a1669f-65eb-457f-88f6-a9290f8852ae)
![HR (2)](https://github.com/user-attachments/assets/b564334d-27cb-4e13-9686-1bab0b65598e)
or you can access the tableau project [here](https://public.tableau.com/shared/RSJ9NDGX4?:display_count=n&:origin=viz_share_link).
## Project Overview
This project was conducted to see the distribution of employees based on gender, race, origin, and other categories. The analysis results are used so that Human Resources can make the right conclusions regarding the development of employee conditions. There are +22200 data from 2000-2020 in the table with different data types. The following is a summary the data and other tools that is used in this project.
+ **Data:** 22214 of HR data from the year 2000 to 2020. 
+ **Data Cleaning and Analysis:** MySQL Workbench
+ **Data Visualization:** Tableau
  
## Objectives
+ **Set Up Human Resources Database**: Create and populate a retail sales database with the provided sales data.
+ **Data Cleaning:** Identify and remove any records with missing or null values.
+ **Exploratory Data Analysis (EDA):** Perform basic exploratory data analysis to understand the dataset.
+ **Data Analysis:** Use SQL to answer specific business questions and derive insights from the sales data.

## Get ready for the analysis!
### 1. Database Setup
+ **Database Creation:** A database named ‘humanresources’ was created and used throughout the project using this query:
``` js
CREATE DATABASE humanresources;
```
+ **Table Creation:** Table named hr is created which is then will be used to save the values from csv file. 
``` js
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
``` 
+ **Data Uploaded:** I am using "LOAD DATA INFILE" command to upload the data from the csv file. This command is much more faster than uploading directly from import wizard.
``` js
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/human resources.csv'
into table hr
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 lines;
select * from hr;
drop table hr;

SET sql_safe_updates = 0;
```
+ **Modify table:** I modified the table, including making changes to column names, changing column data types, adding new columns and more. Here is a query to modify the data table.
``` js
-- 1. Modify column name
alter table hr change column location_sate location_state varchar(50);

-- 2. Modify date formatting in birthdate column
UPDATE hr
SET birthdate = CASE
	WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;
ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

-- 3. Modify date formatting in hire_date column
UPDATE hr
SET hire_date = CASE
	WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;
ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- 4. Modify date formatting in termdate column
UPDATE hr
SET termdate = IF(termdate IS NOT NULL AND termdate !='', date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
WHERE TRUE;
SELECT termdate FROM hr;
SET sql_mode = 'ALLOW_INVALID_DATES';
ALTER TABLE hr
MODIFY COLUMN termdate DATE;

-- 5. Add column age
alter table hr add column age int;
UPDATE hr 
SET age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE());
```

## 2. Data Exploration
+ **Record Count:** Determine the total number of records in the dataset.
+ **Outlier Check:** Check oulier number for age category to determine if there any negative number.
``` js
SELECT * FROM hr;
SELECT COUNT(*) FROM hr;

SELECT MIN(age) AS youngest, MAX(age) AS oldest
FROM hr; -- there is negative number
SELECT COUNT(*)
FROM hr
WHERE age < 18;
SELECT COUNT(*) FROM hr WHERE termdate > CURDATE();
SELECT COUNT(*)
FROM hr
WHERE termdate = '0000-00-00';
```

## 3. Data Analysis
There are several issues related to employee data that must be resolved so that HR understands the distribution of employees in the office. The following is the data analysis as well as the answer

### 1. What is the gender breakdown of employees in the company?
```js
SELECT 
    gender, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY gender;
```

### 2. What is the race ethnicity breakdown of employees in the company?
```js
SELECT 
    race, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY race
ORDER BY COUNT(*) DESC;
```

### 3. What is the age distribution of employees in the company?
```js
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
```

 ### 4. How many employees work at headquarters versus remote locations?
```js
SELECT 
    location, COUNT(location) AS count
FROM hr
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location;
```

### 5. What is the average length of employment for employees who have been terminated?
```js
SELECT 
    ROUND(AVG(DATEDIFF(termdate, hire_date)) / 365, 0) AS avg_length_employment
FROM hr
WHERE
    termdate <= CURDATE()
        AND termdate <> '0000-00-00'
        AND age >= 18;
```

### 6. How does the gender distribution vary across departments and job titles?
```js
SELECT 
    department, gender, COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY department , gender
ORDER BY department;
```

### 7. What is the distribution of job titles in the company?
```js
SELECT 
    jobtitle, COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY jobtitle DESC;
```

### 8. Which department has the highest turnover rate?
```js
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
```

### 9. What is the distribution of employees across the locations by city and state?
```js
SELECT 
    location_state, COUNT(*) AS count
FROM hr
WHERE
    age >= 18 AND termdate = '0000-00-00'
GROUP BY location_state
ORDER BY count DESC;
```

### 10. How has the company's employee count changed over time based on hire and term dates?
```js
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
```

### 11. What is the tenure distribution for each department? (how long employees stay in each department before they quit or fired or something of the sort)?
```js
SELECT 
    department,
    ROUND(AVG(DATEDIFF(termdate, hire_date) / 365), 0) AS avg_tenure
FROM
    hr
WHERE
    termdate <= CURDATE() AND termdate <> '0000-00-00' AND age >= 18
GROUP BY department;
```
