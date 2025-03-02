
USE ProjectPortfolio;

-- review data of coviddeaths
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- review data of covidVaccinations
SELECT *
FROM CovidVaccination
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Reviewing the data we are will be reviwing from CovidDeaths
SELECT
	location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total cases vs total deaths datewise for each location
SELECT
	location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths,
	ROUND(CAST(total_deaths AS float)/total_cases, 2)*100 AS case_vs_death_ratio_percantage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total cases vs total deaths datewise for CANADA
SELECT
	location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths,
	ROUND(CAST(total_deaths AS float)/total_cases, 4)*100 AS case_vs_death_ratio_percantage
FROM CovidDeaths
WHERE location = 'Canada' AND continent IS NOT NULL

ORDER BY location, date;

-- Total cases vs Population datewise for CANADA
SELECT
	location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths,
	ROUND(CAST(total_cases AS float)/population, 4)*100 AS case_vs_population_percantage
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY location, date;

-- Countries with highest infection rate compared to population

SELECT
	location,
	population,
	max(total_cases) as total_infections,
	ROUND((max(total_cases)/population *100),2) as infection_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_rate DESC;

 -- Countries with highest death counts
 SELECT
	location,
	max(CAST(total_deaths as INT)) as total_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_deaths DESC;
 
 -- Countries with highest death counts per polulation
 SELECT
	location,
	population,
	max(CAST(total_deaths as INT)) as total_deaths,
	ROUND(max(CAST(total_deaths as char)/population *100),2) as death_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY death_rate DESC;


 -- Countinents with highest death counts
 SELECT
	location,
	max(CAST(total_deaths as INT)) as total_deaths
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_deaths DESC;


  

--continents with highest death count per population
 With CTE_location_max_deaths AS (
 SELECT
	continent,
	location,
	max(CAST(total_deaths as INT)) as total_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
)
SELECT continent, SUM(total_deaths) as total_deaths
FROM CTE_location_max_deaths
GROUP by continent;

  

  -- Total cases on each date wordwide
  SELECT
	date,
	sum(new_cases) as total_new_cases
  FROM CovidDeaths
  Group BY date;

  -- total deaths on each date and death percentage

   SELECT
	date,
	sum(new_cases) as total_new_cases,
	sum(CAST(new_deaths as float)) as total_new_deaths,
	round(sum(CAST(new_deaths as float))/sum(new_cases),4)*100 as death_percentage
 
  FROM CovidDeaths
  WHERE continent is not NULL
  Group BY date
  Order by date;

-- total deaths and death percentage on global wise
   SELECT
	sum(new_cases) as total_new_cases,
	sum(CAST(new_deaths as float)) as total_new_deaths,
	round(sum(CAST(new_deaths as float))/sum(new_cases),4)*100 as death_percentage
 
  FROM CovidDeaths
  WHERE continent is not NULL


-- Total cases vs total deaths location wise
WITH CTE_total_cases AS (
SELECT
	location,
	SUM(total_cases) AS total_cases
FROM CovidDeaths
GROUP BY location),

CTE_total_deaths AS (
SELECT
	location,
	SUM(CAST(total_deaths AS int)) AS total_deaths
FROM CovidDeaths
GROUP BY location)

SELECT 
	a.location, 
	a.total_cases, 
	b.total_deaths,
	ROUND(CAST(total_deaths AS float)/total_cases, 2)*100 AS case_vs_death_ratio
FROM CTE_total_cases a
 JOIN CTE_total_deaths b
	ON a.location = b.location;


	-- JOIN two tables (deaths and vaccination)
SELECT *
FROM CovidDeaths d
JOIN CovidVaccination v
	ON d.location = v.location AND d.date=v.date;

-- Total population vs vaccination date and location wise
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(CAST(v.new_vaccinations as Float)) over (partition by d.location order by d.location,d.date) as rolling_vaccinated
FROM CovidDeaths d
JOIN CovidVaccination v
	ON d.location = v.location AND d.date=v.date
WHERE d.location is not null
ORDER by location,date;

-- Total population vs vaccination location wise

WITH CTE_rolling_vaccination (continent, location, date, population, new_vaccinations, rolling_vaccinated) AS 
(
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(CAST(v.new_vaccinations as Float)) over (partition by d.location order by d.location,d.date) as rolling_vaccinated
	FROM CovidDeaths d
	JOIN CovidVaccination v
		ON d.location = v.location AND d.date=v.date
	WHERE d.location is not null
	-- ORDER by d.location,d.date
)

SELECT *, ROUND((rolling_vaccinated/population)*100, 2) as population_percentage_vaccinated
FROM CTE_rolling_vaccination;


-- countries with population vs vaccination

WITH CTE_rolling_vaccination (location, total_vaccination) AS 
(
	SELECT d.location, max(CAST(v.total_vaccinations as Float)) as total_vaccination
	FROM CovidDeaths d
	JOIN CovidVaccination v
		ON d.location = v.location AND d.date=v.date
	WHERE d.continent is not null
	GROUP by d.location
),

CTE_population_percentage_vaccinated (location, population, population_percentage_vaccinated) AS 
(
	SELECT d.location, d.population, round(max(CAST(v.total_vaccinations as Float))/d.population * 100,2) as population_percentage_vaccinated
	FROM CovidDeaths d
	JOIN CovidVaccination v
		ON d.location = v.location AND d.date=v.date
	WHERE d.continent is not null
	GROUP by d.location,population
)


SELECT a.location, b.population, a.total_vaccination, b.population_percentage_vaccinated
FROM CTE_rolling_vaccination a
JOIN CTE_population_percentage_vaccinated b
	ON a.location = b.location
ORDER by a.location;



-- TEMP Table
DROP TABLE IF EXISTS PercentPoulationVaccinated;

CREATE TABLE PercentPoulationVaccinated(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population float,
	new_vaccination float,
	rolling_vaccinated float,
	--population_percentage_vaccinated float
	);

INSERT INTO PercentPoulationVaccinated

SELECT d.continent, d.location, d.date, d.population, CAST(v.new_vaccinations as float), sum(CAST(v.new_vaccinations as Float)) over (partition by d.location order by d.location,d.date) as rolling_vaccinated
	FROM CovidDeaths d
	JOIN CovidVaccination v
		ON d.location = v.location AND d.date=v.date
	WHERE d.continent is not null
	-- ORDER by d.location,d.date


SELECT *, CAST(ROUND((rolling_vaccinated/population)*100, 2) as float) as population_percentage_vaccinated
FROM PercentPoulationVaccinated;


-- Cretae view for visualization

DROP VIEW IF exists PercentPoulationVaccinate;
CREATE VIEW PercentPoulationVaccinate as
	SELECT d.continent, d.location, d.date, d.population, CAST(v.new_vaccinations as float) AS new_vaccination, sum(CAST(v.new_vaccinations as Float)) over (partition by d.location order by d.location,d.date) as rolling_vaccinated
	FROM CovidDeaths d
	JOIN CovidVaccination v
		ON d.location = v.location AND d.date=v.date
	WHERE d.continent is not null;
	-- ORDER by d.location,d.date
Select TOP 100 *
FROM PercentPoulationVaccinate
where location = 'Canada' and new_vaccination IS NOT NULL;


