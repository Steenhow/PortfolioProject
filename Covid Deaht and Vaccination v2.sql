SELECT *
FROM PortfolioProject..CovidDeaths

Select * 
From PortfolioProject..CovidVaccination
order by 3,4

--select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Vediamo total cases vs Total deaths
-- Mostra la probabilità di morire di covid nel paese
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Italy'
ORDER BY 1,2

-- total cases vs population
-- Mostra la percentuale di persone che hanno il covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'Italy'
ORDER BY 1,2

-- aggiorno il dato della popolazione italiana

UPDATE CovidDeaths
SET population=59236213
WHERE location= 'Italy'

-- Quali paesi ha il maggior infection rate comaparato alla popolazione non ci interessa la data (OVERALL)

SELECT location, MAX (total_cases) AS HughestInfectionCount, population, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Italy'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--paesi con il numero di morti vs popolazione più alto


SELECT location, MAX (CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Italy'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- facciamo lo stesso per i contenti

SELECT continent, MAX (CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Italy'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--i valori non sono giusti quindi provo a usare i continenti in loc where cont is null

SELECT location, MAX (CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Italy'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

create view MAXcontinetndeathcount as
SELECT location, MAX (CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Italy'
WHERE continent IS NULL
GROUP BY location
--ORDER BY TotalDeathCount DESC

--i valori sono quelli gusti

--potrei definire l'incidenza percentuale del total_death di ogni stato rispetto al continente

--GLOBAL NUMBERS bisogna usare funzioni di aggregazione perchè non posso gruppare tutto per data

SELECT date, SUM(new_cases) AS GlobalDeath, SUM(CAST(new_deaths AS int)) AS GlobalCases, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS GlobalDeathPercentage
from PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY 1,2


-- GLOBAL NUMBERS SENZA DATA
SELECT SUM(new_cases) AS GlobalDeath, SUM(CAST(new_deaths AS int)) AS GlobalCases, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS GlobalDeathPercentage
from PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--GLOBAL Total popuglation vs total vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--sommo i casi totali ma faccio una partizione, interrompo il calcolo quando la location cambia. 
--Devo ordinare la partizione per la data perchè altrimenti aggiunge il totale finale ad ogni giorno
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3 commentato perchè non posso metterlo con CTE
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccinationRate
FROM PopvsVac

--PUOI GUARDARE IL MAX DELLA VacRate

WITH PopvsVac (location, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.location, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
ON dea.location = vac.location 
AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3 commentato perchè non posso metterlo con CTE
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccinationRate
FROM PopvsVac

--NON HO CAPITO COME

-- fare una temp table
--DROP TABLE IF EXISTS #PercentPopulationVaccinated
IF OBJECT_ID('PortfolioProject..PercentPopulationVaccinated') is not null
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3 commentato perchè non posso metterlo con CTE

SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccinationRate
FROM #PercentPopulationVaccinated


--CREIAMO UNA VISUALIZZAZIONE PER USARE I DATI IN FUTURE VISUALIZZAZIONI

CREATE VIEW PercentPopulationVaccination AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3 