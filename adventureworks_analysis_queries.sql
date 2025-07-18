-- ============================================================================
-- Project: AdventureWorksDW SQL Data Analysis
-- Author: Mohamed Rabea
-- Business Requests By: Gemini 
-- Description: A collection of SQL queries performed on the AdventureWorksDW2022
--              sample data warehouse. This project demonstrates various SQL skills
--              including aggregation, joins, CTEs, window functions, and data
--              segmentation to extract business insights from sales and customer data.
-- Dataset: Microsoft AdventureWorksDW2022 Sample Database
-- ============================================================================


-- Task 1: Yearly Sales Performance
-- Business Request: "I need to understand our sales performance over time.
--                   Specifically, I'm interested in seeing the total sales amount
--                   for each calendar year from the start of our data until the end."
SELECT
    DD.CalendarYear,
    SUM(fs.SalesAmount) AS TotalAnnualSales
FROM
    DimDate DD
JOIN
    FactInternetSales fs ON DD.DateKey = fs.OrderDateKey
GROUP BY
    DD.CalendarYear
ORDER BY
    DD.CalendarYear DESC;

------------------------------------------------------------------------------------


-- Task 2: Customer Demographics by Marital Status and Gender
-- Business Request: "I need to see a breakdown of our customers by their marital status
--                   and gender. For each combination, I want to know how many customers
--                   we have. This should include ALL customers in our database,
--                   regardless of whether they've made transactions."
SELECT
    Gender,
    MaritalStatus,
    COUNT(CustomerKey) AS TotalCustomers
FROM
    [AdventureWorksDW2022].[dbo].[DimCustomer]
GROUP BY
    Gender, MaritalStatus
ORDER BY
    TotalCustomers DESC;

------------------------------------------------------------------------------------


-- Task 3: Top N Product Subcategories per Product Category
-- Business Request: "Provide the total sales amount for each product subcategory
--                   within each product category. Identify the top 3 selling product
--                   subcategories within *each* product category.
--                   Exclude any product subcategories that have less than $10,000
--                   in total sales for this analysis."
WITH ProductHierarchy AS (
    -- CTE to join product dimension tables and get category/subcategory names
    SELECT
        dp.ProductKey,
        dpsc.EnglishProductSubcategoryName AS Subcategory,
        dpc.EnglishProductCategoryName AS Category
    FROM
        DimProduct dp
    JOIN
        DimProductSubcategory dpsc ON dp.ProductSubcategoryKey = dpsc.ProductSubcategoryKey
    JOIN
        DimProductCategory dpc ON dpsc.ProductCategoryKey = dpc.ProductCategoryKey
),
SalesPerSubcategory AS (
    -- CTE to calculate Total Sales for each Subcategory within its Category
    SELECT
        ph.Category,
        ph.Subcategory,
        SUM(fs.SalesAmount) AS TotalSales
    FROM
        FactInternetSales fs
    JOIN
        ProductHierarchy ph ON fs.ProductKey = ph.ProductKey
    GROUP BY
        ph.Category, ph.Subcategory
    HAVING
        SUM(fs.SalesAmount) > 10000 -- Filter out low-sales subcategories
),
RankedSales AS (
    -- CTE to rank Subcategories by Total Sales within their respective Categories
    SELECT
        Category,
        Subcategory,
        TotalSales,
        DENSE_RANK() OVER (PARTITION BY Category ORDER BY TotalSales DESC) AS CategoryRank
    FROM
        SalesPerSubcategory
)
SELECT
    Category,
    Subcategory,
    TotalSales,
    CategoryRank
FROM
    RankedSales
WHERE
    CategoryRank < 4 -- Filter for the top 3 ranked subcategories
ORDER BY
    Category, CategoryRank;

------------------------------------------------------------------------------------


-- Task 4: Year-over-Year Sales Comparison (Month-over-Month, Year-over-Year)
-- Business Request: "Provide the total sales amount for each calendar month,
--                   along with the total sales amount for the *same calendar month
--                   in the previous year*. Order by year then month."
SELECT
    dd.CalendarYear,
    dd.MonthNumberOfYear,
    dd.EnglishMonthName,
    SUM(fs.SalesAmount) AS TotalSales,
    -- Uses LEAD window function to fetch sales from the next row in the partition.
    -- Partitioned by month name to compare Jan-Jan, Feb-Feb, etc.
    -- Ordered by year DESC to make LEAD(..., 1) effectively look at the previous year's data.
    LEAD(SUM(fs.SalesAmount), 1, 0) OVER (PARTITION BY dd.EnglishMonthName ORDER BY dd.CalendarYear DESC, dd.MonthNumberOfYear DESC) AS SalesSameMonthLastYear
FROM
    [AdventureWorksDW2022].[dbo].[FactInternetSales] fs
JOIN
    DimDate DD ON fs.OrderDateKey = dd.DateKey
GROUP BY
    dd.CalendarYear, dd.MonthNumberOfYear, dd.EnglishMonthName
ORDER BY
    dd.CalendarYear DESC, dd.MonthNumberOfYear DESC;

------------------------------------------------------------------------------------


-- Task 5: Customer Age Group Segmentation and Sales Contribution
-- Business Request: "Categorize customers into age brackets ('Youth', 'Young Adult',
--                   'Middle-Aged', 'Senior') based on their age as of '2014-01-01'.
--                   For each group, show the total number of customers and their total sales amount.
--                   Order the results by logical age group."
WITH CustomerAgeSegment AS (
    -- Calculate customer age and assign to predefined segments using a CASE statement.
    -- Prefixes (1-, 2-, etc.) are used to ensure logical ordering of segments.
    SELECT
        CustomerKey,
        BirthDate,
        CASE
            WHEN DATEDIFF(year, BirthDate, '2014-01-01') < 25 THEN '1- Youth'
            WHEN DATEDIFF(year, BirthDate, '2014-01-01') >= 25 AND DATEDIFF(year, BirthDate, '2014-01-01') <= 34 THEN '2- Young Adult'
            WHEN DATEDIFF(year, BirthDate, '2014-01-01') >= 35 AND DATEDIFF(year, BirthDate, '2014-01-01') <= 54 THEN '3- Middle-Aged'
            WHEN DATEDIFF(year, BirthDate, '2014-01-01') >= 55 THEN '4- Senior'
            ELSE '5- Other' -- Catch-all for any unclassified ages
        END AS Segment
    FROM
        [AdventureWorksDW2022].[dbo].[DimCustomer]
)
SELECT
    cas.Segment,
    COUNT(DISTINCT cas.CustomerKey) AS CustomersCount,
    SUM(fis.SalesAmount) AS TotalSales
FROM
    CustomerAgeSegment cas
LEFT JOIN
    FactInternetSales fis ON cas.CustomerKey = fis.CustomerKey
GROUP BY
    cas.Segment
ORDER BY
    cas.Segment; -- Orders alphabetically, which aligns with the prefixed logical order

------------------------------------------------------------------------------------


-- Task 6: Sales Distribution by Customer Geography (City Level)
-- Business Request: "Show the total sales amount and the total number of distinct orders
--                   for each city where we have made sales. Only include cities that have
--                   generated more than $50,000 in total sales, to focus on significant areas.
--                   Order the results by total sales amount, descending."
SELECT
    dg.City,
    SUM(fs.SalesAmount) AS TotalSales,
    COUNT(DISTINCT fs.SalesOrderNumber) AS OrdersCount -- Correctly counts distinct sales orders
FROM
    [AdventureWorksDW2022].[dbo].[DimGeography] dg
JOIN
    DimCustomer dc ON dc.GeographyKey = dg.GeographyKey
JOIN
    FactInternetSales fs ON dc.CustomerKey = fs.CustomerKey
GROUP BY
    dg.City
HAVING
    SUM(fs.SalesAmount) > 50000 -- Filters groups based on aggregated sales amount
ORDER BY
    TotalSales DESC;

------------------------------------------------------------------------------------


-- Task 7: Customer Lifetime Value (CLV) Segmentation & Cross-Selling Opportunity
-- Business Request: "Identify 'High Value' (top 20%), 'Medium Value' (next 30%),
--                   and 'Low Value' (remaining 50%) customers based on their total lifetime sales.
--                   For each segment, show:
--                   1. Total number of unique customers.
--                   2. Average total lifetime sales per customer for that segment.
--                   3. The product category that generated the most sales within that segment."
WITH CustomerLifetimeSales AS (
    -- Step 1: Calculate each customer's total lifetime sales (their CLV)
    SELECT
        fs.CustomerKey,
        SUM(fs.SalesAmount) AS TotalLifetimeSales
    FROM
        FactInternetSales AS fs
    GROUP BY
        fs.CustomerKey
),
CustomerSegmented AS (
    -- Step 2: Assign customers to High/Medium/Low Value segments based on their TotalLifetimeSales percentile rank.
    -- High Value: top 20% (PERCENT_RANK >= 0.80)
    -- Medium Value: next 30% (PERCENT_RANK >= 0.50 and < 0.80)
    -- Low Value: remaining 50% (PERCENT_RANK < 0.50)
    SELECT
        cls.CustomerKey,
        cls.TotalLifetimeSales,
        CASE
            WHEN PERCENT_RANK() OVER (ORDER BY cls.TotalLifetimeSales) >= 0.80 THEN 'High Value'
            WHEN PERCENT_RANK() OVER (ORDER BY cls.TotalLifetimeSales) >= 0.50 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS CustomerSegment
    FROM
        CustomerLifetimeSales AS cls
),
SegmentProductSales AS (
    -- Step 3: Calculate total sales for each product category within each customer segment.
    -- This is crucial for identifying the top product category per segment.
    SELECT
        cs.CustomerSegment,
        dpc.EnglishProductCategoryName AS ProductCategory,
        SUM(fis.SalesAmount) AS SalesAmountPerCategoryInSegment
    FROM
        CustomerSegmented AS cs
    JOIN
        FactInternetSales AS fis ON cs.CustomerKey = fis.CustomerKey
    JOIN
        DimProduct AS dp ON fis.ProductKey = dp.ProductKey
    JOIN
        DimProductSubcategory AS dpsc ON dp.ProductSubcategoryKey = dpsc.ProductSubcategoryKey
    JOIN
        DimProductCategory AS dpc ON dpsc.ProductCategoryKey = dpc.ProductCategoryKey
    GROUP BY
        cs.CustomerSegment,
        dpc.EnglishProductCategoryName
),
SegmentSummary AS (
    -- Step 4: Aggregate overall customer counts and average lifetime sales per segment.
    -- This correctly calculates the 'AverageLifetimeSalesPerCustomer' by averaging
    -- the pre-calculated TotalLifetimeSales from the CustomerSegmented CTE.
    SELECT
        CustomerSegment,
        COUNT(DISTINCT CustomerKey) AS SegmentCustomerCount,
        AVG(TotalLifetimeSales) AS AverageLifetimeSalesPerCustomer
    FROM
        CustomerSegmented
    GROUP BY
        CustomerSegment
),
RankedCategorySales AS (
    -- Step 5: Rank product categories by sales amount within each customer segment.
    -- ROW_NUMBER() is used to pick the single top category (rank = 1).
    SELECT
        sps.CustomerSegment,
        sps.ProductCategory,
        sps.SalesAmountPerCategoryInSegment,
        ROW_NUMBER() OVER (PARTITION BY sps.CustomerSegment ORDER BY sps.SalesAmountPerCategoryInSegment DESC) AS RankByCategorySales
    FROM
        SegmentProductSales AS sps
)
-- Final Selection: Combine the Segment Summary (counts, averages) with the Top Product Category for each segment.
SELECT
    ss.CustomerSegment,
    ss.SegmentCustomerCount,
    ss.AverageLifetimeSalesPerCustomer,
    rcs.ProductCategory AS TopCategory,
    rcs.SalesAmountPerCategoryInSegment AS TopCategorySalesAmount
FROM
    SegmentSummary AS ss
LEFT JOIN
    RankedCategorySales AS rcs ON ss.CustomerSegment = rcs.CustomerSegment AND rcs.RankByCategorySales = 1
ORDER BY
    CASE ss.CustomerSegment -- Ensures logical ordering of segments in the final output
        WHEN 'High Value' THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'Low Value' THEN 3
        ELSE 99
    END;