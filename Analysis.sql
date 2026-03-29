USE SalesAnalyticsDB;
GO

-- =========================================
-- SALES ANALYSIS PROJECT
-- =========================================


-- 1. Basic Data Understanding

SELECT COUNT(*) AS Total_Rows
FROM Orders;

SELECT TOP 10 *
FROM Orders;

-- 2. Total Sales

SELECT SUM(Sales) AS Total_Sales
FROM Orders;

-- 3. Total Profit

SELECT SUM(Profit) AS Total_Profit
FROM Orders;

-- 4. Total Orders

SELECT COUNT(DISTINCT Order_ID) AS Total_Orders
FROM Orders;

-- 5. Sales by Category

SELECT 
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Category;

-- =========================================
-- Monthly Sales Trend
-- =========================================

SELECT 
    YEAR(Order_Date) AS Order_Year,
    MONTH(Order_Date) AS Order_Month,
    SUM(Sales) AS Monthly_Sales
FROM Orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Order_Year, Order_Month;

-- =========================================
-- Top Customers Ranking
-- =========================================

SELECT 
    Customer_Name,
    SUM(Sales) AS Total_Sales,
    RANK() OVER (ORDER BY SUM(Sales) DESC) AS Customer_Rank
FROM Orders
GROUP BY Customer_Name
ORDER BY Customer_Rank;

-- =========================================
-- Top Products per Category
-- =========================================

SELECT *
FROM (
    SELECT 
        Category,
        Product_Name,
        SUM(Sales) AS Total_Sales,
        RANK() OVER (PARTITION BY Category ORDER BY SUM(Sales) DESC) AS Rank_In_Category
    FROM Orders
    GROUP BY Category, Product_Name
) t
WHERE Rank_In_Category <= 3
ORDER BY Category, Rank_In_Category;

-- =========================================
-- Running Total Sales
-- =========================================

SELECT 
    Order_Date,
    SUM(Sales) AS Daily_Sales,
    SUM(SUM(Sales)) OVER (ORDER BY Order_Date) AS Running_Total
FROM Orders
GROUP BY Order_Date
ORDER BY Order_Date;

-- =========================================
-- Profit Margin
-- =========================================

SELECT 
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND((SUM(Profit) * 100.0) / NULLIF(SUM(Sales), 0), 2) AS Profit_Margin_Percentage
FROM Orders
GROUP BY Category;

-- =========================================
-- DATA MODELING
-- Create dimension and fact tables
-- =========================================

DROP TABLE IF EXISTS Orders_Fact;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS Products;
GO

-- 1. Customers dimension table
SELECT
    Customer_ID,
    MIN(Customer_Name) AS Customer_Name,
    MIN(Segment) AS Segment,
    MIN(Country_Region) AS Country_Region,
    MIN(City) AS City,
    MIN(State_Province) AS State_Province,
    MIN(Postal_Code) AS Postal_Code,
    MIN(Region) AS Region
INTO Customers
FROM Orders
GROUP BY Customer_ID;
GO

select *
from Customers

-- 2. Products dimension table
SELECT
    Product_ID,
    MIN(Category) AS Category,
    MIN(Sub_Category) AS Sub_Category,
    MIN(Product_Name) AS Product_Name
INTO Products
FROM Orders
GROUP BY Product_ID;
GO

select *
from Products

-- 3. Orders fact table
SELECT
    Row_ID,
    Order_ID,
    Order_Date,
    Ship_Date,
    Ship_Mode,
    Customer_ID,
    Product_ID,
    Sales,
    Quantity,
    Discount,
    Profit
INTO Orders_Fact
FROM Orders;
GO

select *
from Orders_Fact

-- =========================================
-- KEYS
-- =========================================

ALTER TABLE Customers
ALTER COLUMN Customer_ID NVARCHAR(50) NOT NULL;
GO

ALTER TABLE Products
ALTER COLUMN Product_ID NVARCHAR(50) NOT NULL;
GO

ALTER TABLE Orders_Fact
ALTER COLUMN Row_ID INT NOT NULL;
GO

ALTER TABLE Customers
ADD CONSTRAINT PK_Customers PRIMARY KEY (Customer_ID);
GO

ALTER TABLE Products
ADD CONSTRAINT PK_Products PRIMARY KEY (Product_ID);
GO

ALTER TABLE Orders_Fact
ADD CONSTRAINT PK_Orders_Fact PRIMARY KEY (Row_ID);
GO

ALTER TABLE Orders_Fact
ADD CONSTRAINT FK_OrdersFact_Customers
FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID);
GO

ALTER TABLE Orders_Fact
ADD CONSTRAINT FK_OrdersFact_Products
FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID);
GO

-- =========================================
-- JOIN-BASED ANALYSIS
-- =========================================

-- 1. Sales and profit by segment
SELECT
    c.Segment,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit
FROM Orders_Fact o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Segment
ORDER BY Total_Sales DESC;
GO

-- 2. Top 10 customers by sales
SELECT TOP 10
    c.Customer_Name,
    c.Segment,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit
FROM Orders_Fact o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Name, c.Segment
ORDER BY Total_Sales DESC;
GO

-- 3. Top 10 products by profit
SELECT TOP 10
    p.Product_Name,
    p.Category,
    p.Sub_Category,
    SUM(o.Profit) AS Total_Profit
FROM Orders_Fact o
JOIN Products p
    ON o.Product_ID = p.Product_ID
GROUP BY p.Product_Name, p.Category, p.Sub_Category
ORDER BY Total_Profit DESC;
GO

-- 4. Category performance
SELECT
    p.Category,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit,
    SUM(o.Quantity) AS Total_Quantity
FROM Orders_Fact o
JOIN Products p
    ON o.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY Total_Sales DESC;
GO

-- 5. Regional performance
SELECT
    c.Region,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit
FROM Orders_Fact o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region
ORDER BY Total_Sales DESC;
GO

-- =========================================
-- ADVANCED JOIN-BASED BUSINESS ANALYSIS
-- =========================================

-- 1. Top 3 customers in each region by sales
SELECT *
FROM (
    SELECT
        c.Region,
        c.Customer_Name,
        SUM(o.Sales) AS Total_Sales,
        RANK() OVER (
            PARTITION BY c.Region
            ORDER BY SUM(o.Sales) DESC
        ) AS Region_Customer_Rank
    FROM Orders_Fact o
    JOIN Customers c
        ON o.Customer_ID = c.Customer_ID
    GROUP BY c.Region, c.Customer_Name
) t
WHERE Region_Customer_Rank <= 3
ORDER BY Region, Region_Customer_Rank;
GO

-- 2. Top 3 products in each category by profit
SELECT *
FROM (
    SELECT
        p.Category,
        p.Product_Name,
        SUM(o.Profit) AS Total_Profit,
        RANK() OVER (
            PARTITION BY p.Category
            ORDER BY SUM(o.Profit) DESC
        ) AS Category_Product_Rank
    FROM Orders_Fact o
    JOIN Products p
        ON o.Product_ID = p.Product_ID
    GROUP BY p.Category, p.Product_Name
) t
WHERE Category_Product_Rank <= 3
ORDER BY Category, Category_Product_Rank;
GO

-- 3. Monthly sales by region
SELECT
    YEAR(o.Order_Date) AS Order_Year,
    MONTH(o.Order_Date) AS Order_Month,
    c.Region,
    SUM(o.Sales) AS Total_Sales
FROM Orders_Fact o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY
    YEAR(o.Order_Date),
    MONTH(o.Order_Date),
    c.Region
ORDER BY Order_Year, Order_Month, Total_Sales DESC;
GO

-- 4. Profit margin by category
SELECT
    p.Category,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit,
    ROUND((SUM(o.Profit) * 100.0) / NULLIF(SUM(o.Sales), 0), 2) AS Profit_Margin_Percentage
FROM Orders_Fact o
JOIN Products p
    ON o.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY Profit_Margin_Percentage DESC;
GO

-- 5. Loss-making products
SELECT
    p.Product_Name,
    p.Category,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit
FROM Orders_Fact o
JOIN Products p
    ON o.Product_ID = p.Product_ID
GROUP BY p.Product_Name, p.Category
HAVING SUM(o.Profit) < 0
ORDER BY Total_Profit;
GO

-- 6. Average order value by segment
SELECT
    c.Segment,
    SUM(o.Sales) AS Total_Sales,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    ROUND(SUM(o.Sales) / NULLIF(COUNT(DISTINCT o.Order_ID), 0), 2) AS Avg_Order_Value
FROM Orders_Fact o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Segment
ORDER BY Avg_Order_Value DESC;
GO


-- =========================================
-- BUSINESS INSIGHTS
-- =========================================
--Technology has the highest sales and profit.
--Some products generate sales but create negative profit.
--Regional performance is uneven across the business.
--Certain customer segments place higher-value orders.




