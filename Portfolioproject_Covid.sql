SELECT * FROM Coviddeaths WHERE continent is not NULL ORDER BY 3,4; --3 ,4 is used to order third and fourth column

--SELECT * FROM Covidvaccination ORDER BY 3,4;

SELECT location, date, total_cases , new_cases, total_deaths, population FROM Portfolioproject..Coviddeaths ORDER BY 1,2;

--LOOKING AT TOTAL CASES VS TOTAL DEATHS
--SHOWS LIKELIHOOD OF DYING IF YOU GET INFECTED IN YOUR COUNTRY

SELECT location, date, total_cases , total_deaths, (total_deaths/total_cases)*100 as deaths_percentage FROM Portfolioproject..Coviddeaths WHERE Location LIKE 'India' ORDER BY 2 DESC;

--shows infection percentage
SELECT location, date, total_cases, population,(total_cases/population)*100 as infection_percentage FROM Portfolioproject..Coviddeaths ORDER BY 1,2 ;

--Country with highest infection rate

SELECT location, population, MAX(total_cases)as Highestinfectioncount, MAX(total_cases/population)*100 as infection_percentage FROM Portfolioproject..Coviddeaths GROUP BY Location, population ORDER BY infection_percentage desc;

--Countries by highest death count per population

SELECT location, MAX(cast(total_deaths as int)) AS Highestdeathcount FROM Portfolioproject..Coviddeaths WHERE continent is not null GROUP BY location ORDER BY Highestdeathcount desc;

--things are by continent

SELECT continent, MAX(cast(total_deaths as int)) AS Highestdeathcount 
 FROM Portfolioproject..Coviddeaths 
 WHERE continent is not null
 GROUP BY continent
 ORDER BY Highestdeathcount  DESC;

 --GLOBAL NUMBERS BY DATE

 SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases) as deathperpopulation
 FROM Portfolioproject..Coviddeaths 
 WHERE continent is not null
-- GROUP BY date
 ORDER BY 1 DESC;

 --vaccinations

 SELECT * 
 FROM Portfolioproject..Covidvaccination;

 --country with highest vaccination

 /*SELECT location , max(cast(total_tests as int)), max(total_vaccinations) as vaccinations
 from Portfolioproject..Covidvaccination
 where continent is not null
 group by location
 order by vaccinations desc;*/

 SELECT * 
 FROM Portfolioproject..Coviddeaths dea
	JOIN Portfolioproject..Covidvaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date;

--finding out vaccination coverage per country

SELECT dea.location, max(dea.population) as pop, max(cast(vac.total_vaccinations as bigint)) as allvaccinations,ROUND((max(convert(bigint,vac.total_vaccinations))/dea.population)*100, 2, 0) as vacperpopulation
 FROM Portfolioproject..Coviddeaths dea
	JOIN Portfolioproject..Covidvaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
where dea.continent is not null 
GROUP BY dea.location, dea.population
ORDER BY 2 desc;

--ANOTHER WAY IS USING ROLLING COUNT

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY  dea.date) 
AS rollingpeoplevaccinated
--, (rollingpeoplevaccinated/dea.population) cannot use column in calculation which was created in select (SO we'll use CTE)
FROM Portfolioproject..Coviddeaths dea
	JOIN Portfolioproject..Covidvaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3;

-- USE CTE (COMMON TABLE EXPRESSION)

WITH popvsvac (continent, location, date,population, new_vaccinations, rollingpeoplevaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY  dea.date) 
AS rollingpeoplevaccinated
--, (rollingpeoplevaccinated/dea.population) cannot use column in calculation which was created in select (SO we'll use CTE)
FROM Portfolioproject..Coviddeaths dea
	JOIN Portfolioproject..Covidvaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3;
)

SELECT *, (rollingpeoplevaccinated/population)*100 AS vacpenetration 
FROM popvsvac 
WHERE location='Pakistan' 
ORDER BY vacpenetration DESC;

--TEMP TABLE

--DROP TABLE IF EXISTS #PercentPopulationVaccinated (in case you want to edit anything in the table)

CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255), location nvarchar(255), date datetime, population numeric, 
new_vaccinations numeric, rollingpeoplevaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY  dea.date) 
AS rollingpeoplevaccinated
--, (rollingpeoplevaccinated/dea.population) cannot use column in calculation which was created in select (SO we'll use CTE)
FROM Portfolioproject..Coviddeaths dea
	JOIN Portfolioproject..Covidvaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3;
SELECT *, (rollingpeoplevaccinated/population)*100 AS vacpenetration 
FROM #PercentPopulationVaccinated;

--Creating view to store data for visualisation later 

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY  dea.date) 
AS rollingpeoplevaccinated
--, (rollingpeoplevaccinated/dea.population) cannot use column in calculation which was created in select (SO we'll use CTE)
FROM Portfolioproject..Coviddeaths dea
	JOIN Portfolioproject..Covidvaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not NULL;
--ORDER BY 2,3;
 
 SELECT * FROM PercentPopulationVaccinated;