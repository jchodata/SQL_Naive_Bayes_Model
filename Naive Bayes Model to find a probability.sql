--P(A|B): the probability of customer ordering more than $2000 in Southwest territory in US
--P(B|A): the probability of orders made in Southwest territory in US for a customer who orders more than $2000 
--P(A): the overall proportion of ordering more than $2000
--P(B): the overall proportion of customers in US and total order is more than $2000

-- Naive Bayes Model to find a probability by US/NOT US and Southwest/NOT Southwest
--There are four CTEs in this query. The first two calculate the probabilities for the region and territory separately. 

USE AdventureWorks2019;

WITH 
dim1 AS (
	SELECT [Region], 
	--calculating probability if the total order is more than $2000 by Region
			AVG(IIF([Total] > 2000, 1.0 , 0)) AS p
	FROM(
	--
	--the following subquery create a region dimension
		SELECT IIF([Code]='US', 'US', 'NOT US') AS [Region], [Total]
		FROM
		(
		SELECT t.[CountryRegionCode] AS [Code], s.[TotalDue] AS [Total]
		FROM [AdventureWorks2019].[Sales].[SalesOrderHeader] s
		--join with [SalesTerritory] table to get a [CountryRegionCode] column
		JOIN [AdventureWorks2019].[Sales].[SalesTerritory] t
		ON s.[TerritoryID] = t.[TerritoryID]
		)crc
	) rt
	GROUP BY [Region]
),

dim2 AS (
	SELECT [Territory], 
	--calculating probability if the total order is more than $2000 by Territory

			AVG(IIF([Total] > 2000, 1.0 , 0)) AS p
	FROM(
	--the following subquery create a territory dimension
		SELECT IIF([Territory]=4, 'Southwest', 'NOT Southwest') AS [Territory], [Total]
		FROM
		(
		SELECT [TerritoryID] AS [Territory], [TotalDue] AS [Total]
		FROM [AdventureWorks2019].[Sales].[SalesOrderHeader] 
		)tt
	) rt
	GROUP BY [Territory]
),
--The third calculates the probabilities for the overall data.
overall AS (
	SELECT
		AVG(IIF([TotalDue] > 2000, 1.0 , 0)) AS p
	FROM [AdventureWorks2019].[Sales].[SalesOrderHeader]
),
--The fourth calculates the actual probabilities - this will only be used for comparison purpose.
actual AS (
	SELECT Region, Territory,
		AVG(IIF([Total] > 2000, 1.0 , 0)) AS p

	FROM(
	--
	--the following subquery create two columns which are region and territory
		SELECT IIF([CountryCode]='US', 'US', 'NOT US') AS [Region],
		IIF([TerritoryCode]=4, 'Southwest', 'NOT Southwest') AS [Territory],
		[Total]
		FROM
		(
		--the following subquery get the [CountryCode], [TerritoryCode] and the total due
		SELECT t.[CountryRegionCode] AS [CountryCode], s.[TerritoryID] AS [TerritoryCode], s.[TotalDue] AS [Total]
		FROM [AdventureWorks2019].[Sales].[SalesOrderHeader] s
		JOIN [AdventureWorks2019].[Sales].[SalesTerritory] t
		ON s.[TerritoryID] = t.[TerritoryID]
		)crc
	) rt
	GROUP BY Region, Territory
)


SELECT
	Region
	,[Region Probability]
	,Territory
	,[Territory Probability]
	,[Predicted Probability]
	,[Actual Probability]
	--get the difference 
	,[Predicted Probability] - [Actual Probability] AS [Difference]
FROM (
	--the following subquery load all the columns from CTEs
	SELECT
		dim1.Region
		,dim1.p AS [Region Probability]
		,dim2.Territory
		,dim2.p AS [Territory Probability]
		,(dim1.p * dim2.p) / overall.p AS [Predicted Probability]
		,actual.p AS [Actual Probability]
	FROM dim1
	CROSS JOIN dim2
	CROSS JOIN overall
	--join with actual CTE to match the Region and Territory
	JOIN actual
	ON dim1.Region = actual.Region
	AND dim2.Territory = actual.Territory
) dims
ORDER BY Region, Territory

GO