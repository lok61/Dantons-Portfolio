
/*
Covid 19 Data Exploration

Skills used: CTE's, Temp Tables, Windows Functions, Aggregate Functions, Joins, Convert Data Types, Insert function

Inspiration taken from Alex Freburg
*/


SELECT * from "CovidDeaths"
WHERE continent IS NOT NULL 
order by location, date;



--Display the data being used in the most organized way. First by location, then by the date of submission

Select Location, date, total_cases, new_cases, total_deaths, population
FROM "CovidDeaths"
Where continent is not null 
order by total_cases DESC



--Global statistics by cases, deaths, and death percentage
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) as total_deaths, Round((SUM(CAST(new_deaths as int))/ SUM(new_cases)) *100,4) as death_percentage
FROM "CovidDeaths"
Where continent is not null 



--Shows the timeframe for countries with the highest chance of death due to COVID-19 on any specific day
--Using CTE to create a temporary column and utilize aggregates to perform a calculation
with Deaths_per_infected as
(
SELECT date, location,total_cases,  MAX(cast(total_deaths as int)) as Deaths
FROM "CovidDeaths"
WHERE continent IS NOT NULL 
AND total_deaths IS NOT NULL
AND total_cases IS NOT NULL
GROUP BY location, total_cases, date
)

SELECT date, location,  total_cases,deaths, ROUND(MAX(Deaths/Deaths_per_infected.total_cases),3)*100 as death_percentage
FROM Deaths_per_infected
GROUP BY location,deaths, total_cases,date
ORDER BY death_percentage DESC



--Shows the top 10 countries at their peak: highest cases and highest percentage of population infected

Select TOP 10 Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc



--Shows the ratio of new infections to the total amount of people vaccinated up to that date

Select d.continent, d.location, d.date, d.population, d.new_cases, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated ,

CASE
	WHEN SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) = 0
	THEN d.new_cases
	ELSE (d.new_cases / (SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date))) END AS case_to_vac_ratio

FROM CovidDeaths AS d
JOIN CovidVaccinations AS v
	On d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
ORDER BY case_to_vac_ratio DESC




-- Create Temp Table to calculate the case to vaccine ratio in the previous query

DROP Table if exists #case_to_vac_ratio
Create Table #case_to_vac_ratio
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_cases numeric,
RollingPeopleVaccinated numeric,
case_to_vac_ratio int

)

Insert into #case_to_vac_ratio
Select d.continent, d.location, d.date, d.population, d.new_cases, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated, 

CASE
	WHEN SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) = 0
	THEN d.new_cases
	ELSE (d.new_cases / (SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date))) END AS case_to_vac_ratio
	
From CovidDeaths d
JOIN CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
WHERE d.continent is not null 


Select *
From #case_to_vac_ratio
ORDER BY case_to_vac_ratio DESC




--Using Create View for later visualizations 

--Create view for the Infected to Vaccine ratio
Create View CaseToVaccRatio AS

Select d.continent, d.location, d.date, d.population, d.new_cases, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated ,

CASE
	WHEN SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) = 0
	THEN d.new_cases
	ELSE (d.new_cases / (SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date))) END AS case_to_vac_ratio

FROM CovidDeaths AS d
JOIN CovidVaccinations AS v
	On d.location = v.location
	and d.date = v.date
WHERE d.continent is not null




--Create view for the top 10 countries with the highest population infected
Create View Top10Infected AS
Select TOP 10 Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


--Create view to display global statistics for total cases, total deaths, and death percentage
Create View GlobalStatistics AS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) as total_deaths, Round((SUM(CAST(new_deaths as int))/ SUM(new_cases)) *100,4) as death_percentage
FROM "CovidDeaths"
Where continent is not null 


--Create View to display the data general data in our main table
Create View GeneralData AS
Select Location, date, total_cases, new_cases, total_deaths, population
FROM "CovidDeaths"
Where continent is not null 
