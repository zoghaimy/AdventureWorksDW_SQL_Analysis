# AdventureWorksDW SQL Data Analysis

## Project Overview
This repository contains a collection of SQL queries developed to extract business insights from the [Microsoft AdventureWorksDW2022](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16) sample data warehouse. The queries address various business requests, demonstrating a range of SQL skills applied to common data analysis scenarios in an interactive, iterative development process.

## Dataset
The analyses are performed on the `AdventureWorksDW2022` database, a widely used sample data warehouse for SQL Server, representing a bicycle manufacturing company.

## Technologies Used
* **SQL:** Specifically T-SQL (for SQL Server)

## Analysis Performed & Skills Demonstrated

Each query addresses a specific business request provided by an AI assistant (Gemini) and showcases various SQL techniques.

### 1. Yearly Sales Performance
* **Business Request:** Total sales amount for each calendar year.
* **SQL Concepts:** `SUM()`, `GROUP BY`, `ORDER BY`.

### 2. Customer Demographics by Marital Status and Gender
* **Business Request:** Breakdown of customer count by marital status and gender, including all customers in the database.
* **SQL Concepts:** `COUNT()`, `GROUP BY`, `JOIN`s.

### 3. Top N Product Subcategories per Product Category
* **Business Request:** Total sales amount for each product subcategory within each product category. Identify the top 3 selling product subcategories within *each* product category, excluding low-performing ones (sales less than $10,000).
* **SQL Concepts:** Common Table Expressions (CTEs), `SUM()`, `GROUP BY`, `HAVING`, `DENSE_RANK()` window function for ranking within groups, `JOIN`s for data integration.

### 4. Year-over-Year Sales Comparison (Month-over-Month)
* **Business Request:** Total sales for each calendar month, along with the total sales for the *same calendar month in the previous year*.
* **SQL Concepts:** `SUM()`, `GROUP BY`, `LEAD()` window function with `PARTITION BY` and `ORDER BY` for time-series comparison, `JOIN`s.

### 5. Customer Age Group Segmentation and Sales Contribution
* **Business Request:** Categorize customers into age brackets ('Youth', 'Young Adult', 'Middle-Aged', 'Senior') based on their age as of '2014-01-01'. For each group, show the total number of customers and their total sales amount.
* **SQL Concepts:** CTEs, `CASE` statements for conditional logic and categorization, `DATEDIFF()` for age calculation, `COUNT(DISTINCT)`, `SUM()`, `LEFT JOIN` to include all customers, logical ordering techniques.

### 6. Sales Distribution by Customer Geography (City Level)
* **Business Request:** Total sales amount and the total number of distinct orders for each city with sales greater than $50,000.
* **SQL Concepts:** `SUM()`, `COUNT(DISTINCT)` on a unique order identifier (`SalesOrderNumber`) for accurate order count, `GROUP BY`, `HAVING` for post-aggregation filtering, `ORDER BY` for ranking, `JOIN`s for linking geographical and sales data.

### 7. Customer Lifetime Value (CLV) Segmentation & Cross-Selling Opportunity
* **Business Request:** Classify customers into 'High Value' (top 20%), 'Medium Value' (next 30%), and 'Low Value' (remaining 50%) segments based on their total lifetime sales. For each segment, provide:
    1.  Total number of unique customers.
    2.  Average total lifetime sales per customer for that segment.
    3.  The product category that generated the most sales within that specific customer value segment.
* **SQL Concepts:** Multiple CTEs for staged calculations, `SUM()`, `COUNT(DISTINCT)`, `AVG()`, `PERCENT_RANK()` for dynamic segmentation, `ROW_NUMBER()` for top-N analysis within groups, `JOIN`s for complex data integration across multiple dimensions.

---
*This project was developed interactively, simulating real-world business scenarios and iterative query refinement, with business requests provided by an AI assistant (Gemini).*
