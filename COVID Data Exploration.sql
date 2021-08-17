--SELECT * FROM ..[COVID_Deaths];

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ..COVID_Deaths
ORDER BY 1,2

-- MEXICO

-- Total Cases vs Total Deaths Mexico
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ..COVID_Deaths
WHERE location = 'Mexico'
ORDER BY 1,2

-- Total Cases vs Population Mexico
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentageInfected
FROM ..COVID_Deaths
WHERE location = 'Mexico'
ORDER BY 1,2

-- Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfection, MAX((total_cases/population))*100 AS PercentageInfected FROM ..COVID_Deaths
Group BY location, population
ORDER BY PercentageInfected DESC

-- Highest Death Count per Country
SELECT location, MAX(total_deaths) AS TotalDeathCount FROM ..COVID_Deaths
WHERE continent is not NULL
Group BY location
ORDER BY TotalDeathCount DESC

-- Highest Death Count per Continent
SELECT continent, MAX(total_deaths) AS TotalDeathCount FROM ..COVID_Deaths
WHERE continent is NOT NULL
Group BY continent  
ORDER BY TotalDeathCount DESC

-- Cases per Day Worldwide   
SELECT date, SUM(new_cases) as CasesPerDay FROM ..COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Deaths per Day Worldwide
SELECT date, SUM(new_deaths) as DeathsPerDay FROM ..COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Death Percentage People Infected Globally
SELECT date, SUM(new_cases) AS Cases, SUM(new_deaths) AS Deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage FROM ..COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY 1,2

-- Cases vs Deaths Globally
SELECT SUM(new_cases) AS Cases, SUM(new_deaths) AS Deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage FROM ..COVID_Deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Joining Datasets
SELECT * FROM ..COVID_Deaths deaths
JOIN ..[COVID Vaccinations] vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date

-- Vaccinations per Day vs Population
SELECT deaths.continent,deaths.location, deaths.date, vacc.new_vaccinations FROM ..COVID_Deaths deaths
JOIN ..[COVID Vaccinations] vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3


-- Rolling Vaccinations 
SELECT deaths.continent,deaths.location, deaths.date, vacc.new_vaccinations, 
SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccinations FROM ..COVID_Deaths deaths
JOIN ..[COVID Vaccinations] vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3

-- Percentage of Population vs Vaccinations
WITH PercVacc (continent, location, date, population, new_vaccinations, RollingVaccinations)
AS
(
SELECT deaths.continent,deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, 
SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccinations FROM ..COVID_Deaths deaths
JOIN ..[COVID Vaccinations] vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingVaccinations/population)*100 AS PercentagePopVacc FROM PercVacc
ORDER BY location, date 

-- Creating New Table 
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated (
    continent NVARCHAR(50),
    location NVARCHAR(50),
    date DATE,
    population FLOAT,
    new_vaccinations FLOAT,
    RollingVaccinations FLOAT
)
INSERT INTO PercentPopulationVaccinated
SELECT deaths.continent,deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, 
SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccinations FROM ..COVID_Deaths deaths
JOIN ..[COVID Vaccinations] vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL

SELECT *, (RollingVaccinations/population)*100 AS PercentagePopVacc FROM PercentPopulationVaccinated
ORDER BY location, date 

-- Views

-- Death Percentage Mexico
CREATE VIEW DeathPercMexico AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ..COVID_Deaths
WHERE location = 'Mexico'

-- Global Death Percentage
CREATE VIEW GlobalDeathPerc AS
SELECT date, SUM(new_cases) AS Cases, SUM(new_deaths) AS Deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage FROM ..COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY date

-- Percentage Population vs Vaccinations 
CREATE VIEW PopulationVaccination AS
WITH PercVacc (continent, location, date, population, new_vaccinations, RollingVaccinations)
AS
(
SELECT deaths.continent,deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, 
SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccinations FROM ..COVID_Deaths deaths
JOIN ..[COVID Vaccinations] vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL 
)
SELECT *, (RollingVaccinations/population)*100 AS PercentagePopVacc FROM PercVacc
