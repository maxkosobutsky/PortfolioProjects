
SELECT *
From [Portfolio Project]..['Covid Deaths]
WHERE continent is not null
order by 3,4



-- Looking at Total Cases vs Total Deaths
-- This shows likeliihood of dying if you contract Covid-19

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from [Portfolio Project]..['Covid Deaths]
where location like '%states%'
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population that got Covid
select location, date, Population, total_cases, total_deaths, (total_deaths/population)*100 as DeathPercentage
from [Portfolio Project]..['Covid Deaths]
where location like '%states%'
order by 1,2





-- Countries with Highest Infection Rate compared to Population

select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_deaths/total_cases))*100 as PercentInfected
from [Portfolio Project]..['Covid Deaths]
--where location like '%states%'
group by Location, Population
order by PercentInfected desc


-- Showing Countries with Highest Death Count per Population

select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..['Covid Deaths]
WHERE continent is not null
group by Location
order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..['Covid Deaths]
WHERE continent is null
group by location
order by TotalDeathCount desc


-- This is showing the continents with the highest death count per population

select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..['Covid Deaths]
WHERE continent is not null
group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS_____________________________________________________________________

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(casT(New_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from [Portfolio Project]..['Covid Deaths]
WHERE continent is not null
--GROUP BY date
order by 1,2



-- Looking at Total Population vs Vaccinations
-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.New_Vaccinations
, SUM(CONVERT(bigint,vac.New_Vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..['Covid Deaths] dea
JOIN [Portfolio Project]..['Covid Vaccinations] vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



-- TEMP TABLE


DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.New_Vaccinations,
SUM(CONVERT(bigint,vac.New_Vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..['Covid Deaths] dea
JOIN [Portfolio Project]..['Covid Vaccinations] vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Create VIEW to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.New_Vaccinations,
SUM(CONVERT(bigint,vac.New_Vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..['Covid Deaths] dea
JOIN [Portfolio Project]..['Covid Vaccinations] vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated