/*

N.B The data for the following was Originally obtained from: https://ourworldindata.org/covid-deaths

Link to CovidDeaths File: https://github.com/Kimani-99/Portfolio-Projects/blob/main/CovidDeaths.csv
Link to CovidVaccinations File: https://github.com/Kimani-99/Portfolio-Projects/blob/main/CovidVaccinations.csv
*/

/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From Portfolio.dbo.CovidDeaths
Where continent is not null 
order by 3,4

-- Select Data that we are going to be starting with

Select country, date, total_cases, new_cases, total_deaths, population
From Portfolio.dbo.CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select country, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio.dbo.CovidDeaths
order by 1,2

/*
If intersted in finding the likelihood of dying if you contract Covid in a particulat country we
would use the where statement to filter for a particulat country or group of countries. 
Fro example:
*/

Select country, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio.dbo.CovidDeaths
WHERE country = 'Jamaica'
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select country, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Portfolio.dbo.CovidDeaths
--Where country = 'Jamaica''
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select country, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Portfolio.dbo.CovidDeaths
--Where country = 'Jamaica''
Group by country, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select country, MAX(Total_deaths) as TotalDeathCount
From Portfolio.dbo.CovidDeaths
--Where country = 'Jamaica''
Where continent is not null 
Group by country
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From Portfolio.dbo.CovidDeaths
--Where country = 'Jamaica''
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio.dbo.CovidDeaths
--Where country = 'Jamaica''
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea country, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea country Order by dea.country, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio.dbo.CovidDeaths dea
Join Portfolio.dbo.CovidVaccinations vac
	On dea country = vac country
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, country, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea country, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea country Order by dea country, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio.dbo.CovidDeaths dea
Join Portfolio.dbo.CovidVaccinations vac
	On dea country = vac country
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255), country nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea country Order by dea country, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio.dbo.CovidDeaths dea
Join Portfolio.dbo.CovidVaccinations vac
	On dea country = vac country
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea country, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea country Order by dea country, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio.dbo.CovidDeaths dea
Join Portfolio.dbo.CovidVaccinations vac
	On dea country = vac country
	and dea.date = vac.date
where dea.continent is not null 


