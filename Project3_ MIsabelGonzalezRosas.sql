/*
			PROJECT 3
		M. Isabel Gonzalez Rosas
		
*/


-- 1 -- Most heard genre per country 
WITH GenresPerCountry AS (
	SELECT
		country,
		GenreName,
		TotalQuantity
	FROM (	
			SELECT
				c.country,
				g.genreId,
				g.Name AS GenreName,
				SUM(il.quantity) AS 'TotalQuantity'
			FROM InvoiceLine il
				JOIN Track t ON il.trackId = t.trackId
				JOIN Genre g  ON t.genreId = g.genreId
				JOIN Invoice i ON il.invoiceId = i.invoiceId
				JOIN Customer c ON i.customerId = c.customerId
			GROUP BY 1, 2
		) AS PurchasesPerCountry
	ORDER BY 1
)



SELECT
	gen.country,
	gen.genreName,
	gen.TotalQuantity
FROM GenresPerCountry gen
	WHERE TotalQuantity = (	SELECT
								MAX(TotalQuantity)
							FROM GenresPerCountry g
								WHERE g.country = gen.country)

-- Is it the same as the genre on which the best customer on that country more spends?
WITH CustomerPerCountryTotalSpentandGenre AS (
	SELECT
		c.country AS Country,
		c.customerId AS CustomerId,
		c.FirstName || ' ' || c.LastName as CustomerName,
		SUM(i.Total) AS TotalSpent,
		g.Name AS GenreName,
		COUNT(g.genreId) AS GenreCount
	FROM Customer c
		JOIN Invoice i ON c.customerId = i.customerId
		JOIN InvoiceLine il ON i.invoiceId = il.invoiceId
		JOIN Track t ON il.trackId = t.trackId
		JOIN Genre g ON t.genreId = g.genreId
	GROUP BY 1, 2, 5
	ORDER BY 1
)


SELECT
	c.Country,
	c.CustomerId,
	c.CustomerName,
	c.TotalSpent,
	c.GenreName,
	c.GenreCount
FROM CustomerPerCountryTotalSpentandGenre c
GROUP BY 1, 2,5
HAVING c.TotalSpent = (	SELECT
							MAX(TotalSpent)
						FROM CustomerPerCountryTotalSpentandGenre cc
							WHERE cc.country = c.Country)

-------------------------------------------------------------------------------------------------------------------------------------------------
-- 2-- Is there a difference in track length according to country?
-- median: https://stackoverflow.com/questions/15763965/how-can-i-calculate-the-median-of-values-in-sqlite 	

--Total
SELECT 
		min(t.milliseconds) AS Minimum,
		( 
		SELECT avg(milliseconds)
			FROM  (
					SELECT milliseconds
						FROM Track
						ORDER BY milliseconds
						LIMIT 2 - (SELECT (COUNT(*)/2)-1 FROM Track) % 2
						OFFSET (SELECT (COUNT(*)-1) / 4	 FROM Track) 
					) 
		) AS q1,
		( 
		SELECT avg((
					SELECT milliseconds
						FROM Track
					ORDER BY milliseconds
					LIMIT 2 - (SELECT COUNT(*) FROM Track) % 2 -- odd 1, even 2
					OFFSET (SELECT (COUNT(*) -1) /2 FROM Track) 
					))
		)AS Median,		
		(
		SELECT avg(milliseconds)
			FROM (
					SELECT milliseconds
						FROM Track
					ORDER BY milliseconds
					LIMIT 2 - (SELECT (COUNT(*)/2)-1 FROM Track) % 2
					OFFSET (SELECT (COUNT(*)-1)/4 *3 +1 FROM Track) 
				) 
		) AS q3,		
		max(t.milliseconds) AS Maximum,
		(
		SELECT avg(milliseconds)
			FROM track) AS Mean,
		max(t.milliseconds)- min(t.milliseconds) AS Range
FROM Track t
LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
LEFT JOIN Customer c ON i.customerId= c.customerId

--by country

WITH MillisecondsPerCountry AS
	(SELECT 
		c.country AS country,
        t.milliseconds AS Milliseconds,
		(
		SELECT count(*)
			FROM Track t
		LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
		LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
		LEFT JOIN Customer cu ON i.customerId= cu.customerId
			WHERE cu.country = c.country 
		) AS CountryCount,
        CASE
            WHEN(--EVEN
				SELECT count(*)
                    FROM Track t
                LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
                LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
                LEFT JOIN Customer cu ON i.customerId= cu.customerId
					WHERE cu.country = c.country ) %2 = 0 
			THEN 
				CASE
                    WHEN (--even even
						SELECT (count(*)-2)/2
                            FROM Track t
                        LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
                        LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
                        LEFT JOIN Customer cu ON i.customerId= cu.customerId
                            WHERE cu.country = c.country ) %2 = 0 --even-even (ex. 6 _ _ |_ _| _ _ )
					THEN 'even-even'
					ELSE 'even-odd' -- (ex. 4 _ |_ _|  _ )
		        END
            ELSE -- ODD
				CASE
					WHEN (-- odd- even
						SELECT (count(*)-1)/2
							FROM Track t
						LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
						LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
						LEFT JOIN Customer cu ON i.customerId= cu.customerId
							WHERE cu.country = c.country ) %2 = 0 --odd-even (ex. 5 _ _ |_| _ _ )
					THEN 'odd-even'
					ELSE 'odd-odd' -- (ex 7 _ _ _ |_| _ _ _ )
				END
		END AS OddEven,
        CASE
            WHEN (--EVEN
				SELECT count(*)
                    FROM Track t
                LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
                LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
                LEFT JOIN Customer cu ON i.customerId= cu.customerId
                    WHERE cu.country = c.country ) %2 = 0 
			THEN  (SELECT (count(*)-2)/2 
						FROM Track t
					LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
					LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
					LEFT JOIN Customer cu ON i.customerId= cu.customerId
						WHERE cu.country = c.country
					)
            ELSE ( -- ODD
                SELECT (count(*)-1)/2
                    FROM Track t
                LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
                LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
                LEFT JOIN Customer cu ON i.customerId= cu.customerId
                    WHERE cu.country = c.country
				)
        END AS halfWithoutMedian
			FROM Track t
	LEFT JOIN InvoiceLine il ON t.trackId = il.trackId
	LEFT JOIN Invoice i ON il.invoiceId = i.invoiceId
	LEFT JOIN Customer c ON i.customerId= c.customerId
		WHERE c.country IS NOT NULL
   GROUP BY 1, 2
   ORDER BY 1, 2
   )
   
   
SELECT 
	m.Country AS Country,
    MIN(m.Milliseconds) AS Minimum,
	(SELECT avg(milliseconds)
		FROM (
				SELECT t.milliseconds
					FROM MillisecondsPerCountry t
						WHERE t.Country= m.Country
				LIMIT (SELECT CASE WHEN mil.OddEven LIKE '%-even' THEN 2  ELSE 1     END
							FROM MillisecondsPerCountry mil
								WHERE mil.Country= Country)
				OFFSET (SELECT (mil.halfWithoutMedian - (SELECT CASE  WHEN mil.OddEven LIKE '%-even' THEN 2 ELSE 1   END
															FROM MillisecondsPerCountry mil
														WHERE mil.Country= Country))/2
							FROM MillisecondsPerCountry mil
						WHERE mil.Country= Country)
		 )
	) AS q1,
	(SELECT avg(milliseconds)
		FROM (
			SELECT t.milliseconds
				FROM MillisecondsPerCountry t
				WHERE t.Country= m.Country
			LIMIT (SELECT CASE WHEN mil.OddEven LIKE 'even-%' THEN 2 ELSE 1 END
						FROM MillisecondsPerCountry mil
							WHERE mil.Country= Country)
			OFFSET (SELECT mil.halfWithoutMedian
						FROM MillisecondsPerCountry mil
							WHERE mil.Country= Country)
			)
	) AS Median,
	(SELECT avg(milliseconds)
		FROM (
			SELECT t.milliseconds
				FROM MillisecondsPerCountry t
					WHERE t.Country= m.Country
			LIMIT (SELECT CASE WHEN mil.OddEven LIKE '%-even' THEN 2 ELSE 1  END
						FROM MillisecondsPerCountry mil
							WHERE mil.Country= Country)
			OFFSET (SELECT mil.halfWithoutMedian + (SELECT CASE WHEN mil.OddEven LIKE 'even-%' THEN 2 ELSE 1   END
														FROM MillisecondsPerCountry mil
															WHERE mil.Country= Country) 
					+ (mil.halfWithoutMedian - (SELECT CASE WHEN mil.OddEven LIKE '%-even' THEN 2  ELSE 1 END
													FROM MillisecondsPerCountry mil
														WHERE mil.Country= Country))/2
						FROM MillisecondsPerCountry mil
							WHERE mil.Country= Country
					)
			)
	) AS q3,
    max(m.Milliseconds)AS Maximum,
    AVG(m.Milliseconds) AS Mean,
    max(m.Milliseconds)-min(m.Milliseconds) AS Range
FROM MillisecondsPerCountry m
GROUP BY m.country

-------------------------------------------------------------------------------------------------------------------------------------------------

--3 -- Is there a relationship between Genre and MediaType?
SELECT g.Name AS GenreName,
       m.Name AS Media,
       count(m.MediaTypeId) AS MediaCount
FROM Genre g
JOIN Track t ON g.genreId = t.genreId
JOIN MediaType m ON t.mediatypeId = m.mediatypeId
GROUP BY 1, 2
ORDER BY 1
	

-------------------------------------------------------------------------------------------------------------------------------------------------
	
--4 --- Is there a tendency among artists regarding their income and the genre they are composing?
SELECT g.name AS GenreName,
       sum(il.unitPrice*il.quantity) AS TotalIncome,
       sum(il.quantity) AS QuantitySold,
       sum(il.unitPrice*il.quantity)/sum(il.quantity) AS AveragePricePerTrack
FROM Genre g
JOIN Track t ON g.genreId = t.genreId
JOIN InvoiceLine il ON t.trackId = il.trackId
JOIN Album al ON t.albumId = al.albumId
JOIN Artist a ON al.artistId = a.artistId
GROUP BY 1
ORDER BY 2 DESC


-------------------------------------------------------------------------------------------------------------------------------------------------

-- 5 -- What’s the average income per employee per day?

SELECT e.FirstName || ' ' || e.LastName AS EmployeeName,
       e.hireDate,
       max(i.invoicedate) LastInvoiceDate,
       max(i.invoicedate) - e.hireDate AS WorkedDays,
       sum(i.total) AS TotalSold,
       sum(i.total)/ (max(i.invoicedate) - e.hireDate) AS AverageIncomePerDay
FROM Employee e
JOIN Customer c ON e.EmployeeId = c.SupportRepId
JOIN Invoice i ON c.customerId = i.customerId
GROUP BY e.employeeId



















