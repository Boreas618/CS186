-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*) AS count
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, avgheight, count
  FROM(
    SELECT birthyear, AVG(height) AS avgheight, COUNT(*) AS count
    FROM people
    GROUP BY birthyear
    ORDER BY birthyear
  )
  WHERE avgheight > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, halloffame.playerid as playerid, yearid
  FROM people INNER JOIN halloffame
  ON people.playerid = halloffame.playerid
  WHERE inducted = "Y"
  ORDER BY yearid DESC, halloffame.playerid
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, hofInfo.playerid, schoolid, yearid
  FROM (
    SELECT playerid, schoolstate, collegeplaying.schoolid AS schoolid
    FROM schools INNER JOIN collegeplaying
    ON schools.schoolid = collegeplaying.schoolid
  ) AS stateinfo INNER JOIN (
    SELECT namefirst, namelast, halloffame.playerid as playerid, yearid
    FROM people INNER JOIN halloffame
    ON people.playerid = halloffame.playerid
    WHERE inducted = "Y"
  ) AS hofinfo
  ON hofinfo.playerid = stateinfo.playerid
  WHERE schoolstate = "CA"
  ORDER BY yearid DESC, schoolid, hofinfo.playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT hofInfo.playerid, namefirst, namelast, schoolid AS schoolid -- replace this line
  FROM (
    SELECT namefirst, namelast, halloffame.playerid as playerid, yearid
    FROM people INNER JOIN halloffame
    ON people.playerid = halloffame.playerid
    WHERE inducted = "Y"
  ) AS hofinfo LEFT OUTER JOIN collegeplaying
  ON hofinfo.playerid = collegeplaying.playerid
  ORDER BY hofinfo.playerid DESC, schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid AS playerid, namefirst, namelast, yearid AS yearid, slg -- replace this line
  FROM (
    SELECT playerid, CAST((H-H2B-H3B-HR+2*H2B+3*H3B+4*HR) AS float)/CAST(AB AS float) AS slg, yearid
    FROM Batting
    WHERE AB > 50
    ORDER BY slg DESC
    LIMIT 10
  ) AS b LEFT OUTER JOIN people AS p
  ON p.playerid = b.playerid
  ORDER BY slg DESC, yearid, p.playerid
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid AS playerid, namefirst, namelast, b.lslg -- replace this line
  FROM (
    SELECT playerid, CAST((SUM(H-H2B-H3B-HR)+2*SUM(H2B)+3*SUM(H3B)+4*SUM(HR)) AS float)/CAST(SUM(AB) AS float) AS lslg
    FROM batting
    GROUP BY playerid
    HAVING SUM(AB) > 50
    ORDER BY lslg DESC
    LIMIT 10
  ) AS b LEFT OUTER JOIN people AS p
  ON p.playerid = b.playerid
  ORDER BY b.lslg DESC, p.playerid
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  WITH joined_table AS(
    SELECT p.playerid, namefirst, namelast, b.lslg, ROW_NUMBER() OVER(ORDER BY b.lslg DESC) AS row_num
    FROM (
      SELECT playerid, CAST((SUM(H-H2B-H3B-HR)+2*SUM(H2B)+3*SUM(H3B)+4*SUM(HR)) AS float)/CAST(SUM(AB) AS float) AS lslg
      FROM batting
      GROUP BY playerid
      HAVING SUM(AB) > 50
    ) AS b LEFT OUTER JOIN people AS p
    ON p.playerid = b.playerid
    ORDER BY b.lslg DESC
  )

  SELECT namefirst, namelast, lslg -- replace this line
  FROM joined_table
  WHERE row_num < (
    SELECT row_num
    FROM joined_table
    WHERE playerid = "mayswi01"
  )
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary) -- replace this line
  FROM Salaries
  GROUP BY yearid
  ORDER BY yearid
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH filtered_table AS (
    SELECT *
    FROM salaries
    WHERE yearid = 2016
  )

  SELECT binid, minval+binid*bin AS low, minval+(binid+1)*bin AS high, COUNT(*) AS count
  FROM(
    SELECT salary, CASE WHEN CAST(FLOOR ((salary-minval)/CAST((maxval-minval) AS FLOAT)*10) AS INT) = 10 THEN 9 ELSE CAST(FLOOR ((salary-minval)/CAST((maxval-minval) AS FLOAT)*10) AS INT) END AS binid
    FROM filtered_table, (SELECT MIN(salary) AS minval FROM filtered_table), (SELECT MAX(salary) AS maxval FROM filtered_table)
  ) AS salary_bins, (SELECT (MAX(salary)-MIN(salary))/10.0 AS bin FROM filtered_table),(SELECT MIN(salary) AS minval FROM filtered_table)
  GROUP BY binid;
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH salary_league AS (
    SELECT yearid, MIN(salary) AS min, MAX(salary) AS max, AVG(salary) AS avg
    FROM Salaries
    GROUP BY yearid
  )
  SELECT yearid, (min - LAG(min) OVER (ORDER BY yearid)) AS mindiff, (max - LAG(max) OVER (ORDER BY yearid)) AS maxdiff, (avg - LAG(avg) OVER (ORDER BY yearid)) AS avgdiff -- replace this line
  FROM salary_league
  LIMIT 1, (SELECT COUNT(*) - 1 FROM salary_league);
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH max_2000 AS (
    SELECT playerID, namefirst, namelast, salary, yearid
    FROM (
        SELECT *, RANK() OVER (ORDER BY salary DESC) AS salary_rank
        FROM Salaries
        INNER JOIN people ON Salaries.playerID = people.playerID
        WHERE yearid = 2000
    ) AS subquery
    WHERE salary_rank = 1
  ), max_2001 AS (
    SELECT playerID, namefirst, namelast, salary, yearid
    FROM (
        SELECT *, RANK() OVER (ORDER BY salary DESC) AS salary_rank
        FROM Salaries
        INNER JOIN people ON Salaries.playerID = people.playerID
        WHERE yearid = 2001
    ) AS subquery
    WHERE salary_rank = 1
  )
  SELECT * FROM max_2000 UNION SELECT * FROM max_2001;
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamID AS team, MAX(s.salary) - MIN(s.salary) AS diffAvg
  FROM allstarfull a
  INNER JOIN Salaries s ON a.playerID = s.playerID AND a.teamID = s.teamID AND a.yearID = s.yearID
  WHERE a.yearID = 2016 AND s.yearID = 2016
  GROUP BY a.teamID;
;

