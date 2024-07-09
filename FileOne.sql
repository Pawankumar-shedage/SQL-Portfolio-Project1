--SELECT *
--FROM PortfolioProject..CovidVaccinations

--SELECT * 
--FROM PortfolioProject..CovidDeaths
--ORDER BY 3,4

USE [PortfolioProject]
--Table description
--EXEC sp_help CovidDeaths

---SELECTING DATA

SELECT location,date,total_cases,new_cases, total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


--Looking at total cases VS total deaths in a specfic country

SELECT location,date,total_cases, total_deaths, (cast(total_deaths as float)/(cast (total_cases as float)) ) * 100  AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'India' AND total_cases IS NOT  NULL AND total_deaths IS NOT NULL
--WHERE location like '%states%' and date = '2021-04-30 00:00:00.000'
ORDER BY 1,2


--Looking at total_cases Vs total population. (To calculate percentage of people in a country who have covid)

SELECT location,date,total_cases, population, (cast (total_cases as float))/(cast(population as int) ) * 100  AS CovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'India'  AND total_cases IS NOT NULL AND population IS NOT NULL
ORDER BY 1,2

--Looking at Highest Infection rate compared to Population.

SELECT location,MAX(CAST(total_cases as int)) HighestCases,population As TotalPopulation, 
	(MAX(CAST(total_cases AS FLOAT)) / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC


--Showing countries with Highest Death Count per population

SELECT location,MAX(CAST(total_deaths as int)) AS TotalDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY TotalDeaths DESC


--BY CONTINENT
SELECT continent,MAX(CAST(total_deaths as int)) AS TotalDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC


--VIEW  For Total Deaths by Continent
CREATE VIEW TotalDeathsByContinent AS
SELECT continent,MAX(CAST(total_deaths as int)) AS TotalDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent


--VIEW FOR Total Deaths By Country.
CREATE VIEW TotalDeathsPerCountry AS
SELECT location As Country,MAX(CAST(total_deaths as int)) AS TotalDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location




---GLOBAL COUNT
USE [PortfolioProject]

-- TOTAL CASES AND TOTAL DEATHS acroos the world

SELECT SUM(CAST (new_cases as float)) AS TotalCases,SUM(CAST (new_deaths as float)) as Total_Deaths, 
	SUM(CAST (new_deaths as float))/SUM(CAST (new_cases as float)) * 100 As DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL



--VACCINATIONS
SELECT * 
FROM [PortfolioProject]..CovidVaccinations

--DESC TABLE
exec sp_help CovidDeaths
exec sp_help CovidVaccinations

--Looking at Vaccinations Vs Total Population

SELECT dea.continent,dea.location,dea.date,vac.new_vaccinations

FROM [PortfolioProject]..CovidDeaths dea
JOIN [PortfolioProject]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

WHERE dea.continent IS NOT NULL AND vac.total_vaccinations IS NOT NULL
ORDER BY 2,3


--Rolling sum of new vaccinations
SELECT dea.continent,dea.location,dea.date,vac.new_vaccinations,
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS TotalPeopleVaccinatedTillDate,
	dea.population
FROM [PortfolioProject]..CovidDeaths dea
JOIN [PortfolioProject]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

WHERE dea.continent IS NOT NULL AND vac.total_vaccinations IS NOT NULL
ORDER BY 2,3


--Looking at percentage of people vaccinated till date. 
	
--1.WITH TEMP TABLE

DROP TABLE IF EXISTS #PercentPeopleVaccinated

SELECT dea.continent,dea.location,dea.date,vac.new_vaccinations,
		SUM(CONVERT(int,CONVERT(float,vac.new_vaccinations))) OVER (PARTITION BY dea.location ORDER BY dea.date) AS TotalPeopleVaccinatedTillDate,
		dea.population 
	INTO #PercentPeopleVaccinated
FROM [PortfolioProject]..CovidDeaths dea
JOIN [PortfolioProject]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.total_vaccinations IS NOT NULL
ORDER BY 2,3
	  
SELECT *,(TotalPeopleVaccinatedTillDate/Population) * 100 AS PercentPeopleVaccinated
FROM #PercentPeopleVaccinated


--WITH CTE

WITH VacVsPop (Continent,Location,Date,New_Vaccinations,TotalPeopleVaccinatedTillDate,Population)
AS 
(
	SELECT dea.continent,dea.location,dea.date,vac.new_vaccinations,
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS TotalPeopleVaccinatedTillDate,
	dea.population
	FROM [PortfolioProject]..CovidDeaths dea
	JOIN [PortfolioProject]..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date

	WHERE dea.continent IS NOT NULL AND vac.total_vaccinations IS NOT NULL
)
SELECT *, (TotalPeopleVaccinatedTillDate/Population)*100 As VaccinatedPeople
FROM VacVsPop

-------------------------------------------------------------------------


--Creating Views for storing data and using that for Visualizations.

CREATE VIEW PercentPeopleVaccinated
AS
	(SELECT dea.continent,dea.location,dea.date,vac.new_vaccinations,
		SUM(CONVERT(int,CONVERT(float,vac.new_vaccinations))) OVER (PARTITION BY dea.location ORDER BY dea.date) 
			AS TotalPeopleVaccinatedTillDate,
		dea.population 
	FROM [PortfolioProject]..CovidDeaths dea
	JOIN [PortfolioProject]..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL AND vac.total_vaccinations IS NOT NULL
)

SELECT * FROM PercentPeopleVaccinated
