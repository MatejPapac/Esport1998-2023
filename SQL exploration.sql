--1. What are the top 5 games by total earnings?
SELECT sum(totalearnings) as Earnings,
game
FROM general
GROUP BY Game
ORDER BY earnings DESC
LIMIT 5;


--2.How have esports earnings evolved over the years?
SELECT EXTRACT(YEAR from cast(date as DATE)) as years,
avg(earnings) as average_earning,
sum(earnings) as total_earnings,
count(tournaments) as tournaments
FROM historical
GROUP BY years
ORDER BY years;


--3. Which genre has the highest average earnings in esports over the years?
SELECT 
    g.genre,
    EXTRACT(YEAR FROM CAST(h.date AS DATE)) AS years,
    ROUND(AVG(g.totalEarnings)::numeric, 2) AS average  
FROM 
    general g
JOIN 
    historical h 
ON 
    g.game = h.game
GROUP BY 
    years, g.genre
ORDER BY 
    average DESC
;



--4. Is there a correlation between the number of players in a game and its total earnings?
SELECT total_players,totalearnings,game
from general
ORDER BY total_players desc;


--5. What is the trend in the number of esports tournaments over time?
SELECT 
    EXTRACT(YEAR FROM CAST(h.date AS DATE)) AS years,
    COUNT(h.tournaments) AS tournament_count -- Replace with the appropriate aggregation
FROM 
    general g
JOIN 
    historical h 
ON 
    g.game = h.game
GROUP BY 
    years
ORDER BY 
    years ASC;


    
--6. How does the age of a game (years since release) 
--affect its popularity in esports (measured by the number of players or tournaments)?
select releasedate,
total_players ,totaltournaments,game
FROM general
order by total_players desc,totaltournaments desc;

--7. Which games have the highest percentage of offline earnings?
select game,offline_earnings,percent_offline,totaltournaments
from general
WHERE totaltournaments > 5
ORDER BY percent_offline desc;

--8. Are newer games (released in the last 5 years) earning more in esports compared to older games?
WITH CategorizedGames AS (
    SELECT
        g.game,
        g.releasedate,
        CASE
            WHEN g.releasedate >= EXTRACT(YEAR FROM CURRENT_DATE) - 5 THEN 'New'
            ELSE 'Old'
        END AS game_age_category,
        SUM(h.earnings) as total_earnings
    FROM
        general g
    JOIN
        historical h ON g.game = h.game
    GROUP BY
        g.game, g.releasedate
)

SELECT
    game_age_category,
    AVG(total_earnings) as average_earnings
FROM
    CategorizedGames
GROUP BY
    game_age_category;
	
--10. What is the impact of offline events on the popularity of games (measured by player count) 
--and their earnings, especially in light of any recent global events that may have shifted esports online?
	SELECT 
    EXTRACT(YEAR FROM CAST(date AS DATE)) AS event_year,
    g.game,
    AVG(g.total_players) AS average_player_count,
    SUM(h.earnings) AS total_game_earnings,
    AVG(g.percent_offline) AS average_percent_offline
FROM 
    general g
JOIN 
    historical h ON g.game = h.game
WHERE
    date BETWEEN '2013' AND '2023'
	AND totaltournaments > 20
GROUP BY 
    event_year, g.game
ORDER BY 
    average_percent_offline DESC;
--11.Which game genres are gaining or losing market share in terms of player base, and how does this correlate with changes 
--in the total earnings of those genres year over year?
WITH GenreYearlyStats AS (
SELECT
g.genre,
EXTRACT(YEAR FROM CAST(h.date AS DATE)) AS year,
SUM(h.players) OVER (PARTITION BY g.genre, EXTRACT(YEAR FROM CAST(h.date AS DATE))) as yearly_players,
SUM(h.earnings) OVER (PARTITION BY g.genre, EXTRACT(YEAR FROM CAST(h.date AS DATE))) as yearly_earnings
FROM general g
JOIN historical h 
ON g.game=h.game
),
TotalPlayersPerYear AS (
	SELECT 
	year,
	SUM(yearly_players) as total_players
	FROM GenreYearlyStats
	GROUP BY year
),
GenreMarketShare AS (
    SELECT 
        a.genre,
        a.year,
        a.yearly_players,
        a.yearly_earnings,
        (a.yearly_players::decimal / b.total_players) * 100 as market_share_percentage,
        LAG(a.yearly_players::decimal / b.total_players, 1) OVER (PARTITION BY a.genre ORDER BY a.year) * 100 as last_year_market_share
    FROM GenreYearlyStats a
	JOIN TotalPlayersPerYear b ON a.year=b.year
	)
SELECT genre,
year,
 market_share_percentage,
    last_year_market_share,
    market_share_percentage - last_year_market_share as change_in_market_share,
    yearly_earnings
FROM 
    GenreMarketShare
ORDER BY 
    change_in_market_share ASC,
    genre, 
    year;
	
SELECT 
    * 
FROM 
    general g
JOIN 
    historical h 
ON 
    g.game = h.game
    