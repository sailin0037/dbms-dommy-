-- ShopSphere | Week 15 | SQL demonstration and business intelligence reports.
USE shopsphere_capstone;

-- Basic SQL: SELECT, WHERE, ORDER BY, DISTINCT, LIKE, BETWEEN.
SELECT CustomerID, Name, City FROM Customer WHERE City = 'Chennai' ORDER BY Name;
SELECT DISTINCT City FROM Customer ORDER BY City;
SELECT ProductID, Name, Price FROM Product
WHERE Name LIKE 'Laptop%' AND Price BETWEEN 50000 AND 80000 ORDER BY Price;

-- Joins, aggregates, GROUP BY and HAVING.
SELECT s.StoreName, COUNT(*) AS Listings, SUM(i.StockQuantity) AS UnitsInStock
FROM Seller s JOIN Inventory i ON i.SellerID = s.SellerID
GROUP BY s.SellerID, s.StoreName HAVING COUNT(*) >= 5
ORDER BY UnitsInStock DESC, s.StoreName;
SELECT * FROM v_CustomerOrderHistory WHERE CustomerID = 1 ORDER BY OrderDate DESC, OrderID DESC;

-- Subquery and nested query: above-average prices and buyers of Electronics.
SELECT p.Name, p.Price FROM Product p
WHERE p.Price > (SELECT AVG(Price) FROM Product) ORDER BY p.Price DESC;
SELECT c.CustomerID, c.Name FROM Customer c
WHERE EXISTS (SELECT 1 FROM v_PaidOrderItems li WHERE li.CustomerID = c.CustomerID
              AND li.ProductID IN (SELECT p.ProductID FROM Product p WHERE p.CategoryID = 1))
ORDER BY c.CustomerID;

-- Sales intelligence: lifetime revenue, monthly trend, bestsellers and category revenue.
SELECT COUNT(*) AS PaidOrders, COALESCE(SUM(TotalAmount), 0) AS TotalRevenue FROM v_PaidOrders;
SELECT * FROM v_SalesReport ORDER BY SalesMonth;
SELECT ProductName, QuantitySold, Revenue, RANK() OVER (ORDER BY QuantitySold DESC) AS SalesRank
FROM v_ProductPerformance WHERE QuantitySold > 0
ORDER BY SalesRank, Revenue DESC, ProductID LIMIT 10;
SELECT c.CategoryName, COUNT(DISTINCT li.OrderID) AS Orders, SUM(li.Quantity) AS UnitsSold,
       SUM(li.LineRevenue) AS Revenue
FROM v_PaidOrderItems li JOIN Product p ON p.ProductID = li.ProductID
JOIN Category c ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName ORDER BY Revenue DESC, c.CategoryID;

-- Customer intelligence: high-value customers, frequency and segment totals.
SELECT CustomerID, Name, TotalPurchases AS PurchaseFrequency, TotalSpending, Segment,
       DENSE_RANK() OVER (ORDER BY TotalSpending DESC) AS SpendingRank
FROM v_CustomerSegmentation ORDER BY SpendingRank, CustomerID;
SELECT Segment, COUNT(*) AS Customers, SUM(TotalPurchases) AS Orders, SUM(TotalSpending) AS Revenue
FROM v_CustomerSegmentation GROUP BY Segment ORDER BY Revenue DESC;

-- Inventory intelligence: low stock, overstock and fast-moving products.
SELECT i.SKU, p.Name AS ProductName, s.StoreName, i.StockQuantity, i.ReorderLevel,
       CASE WHEN i.StockQuantity <= i.ReorderLevel THEN 'Low stock'
            WHEN i.StockQuantity >= 100 THEN 'Overstocked' ELSE 'Normal' END AS StockStatus
FROM Inventory i JOIN Product p ON p.ProductID = i.ProductID
JOIN Seller s ON s.SellerID = i.SellerID
WHERE i.StockQuantity <= i.ReorderLevel OR i.StockQuantity >= 100
ORDER BY i.StockQuantity, i.SKU;
SELECT ProductName, QuantitySold, AvailableStock FROM v_ProductPerformance
WHERE QuantitySold >= 8 ORDER BY QuantitySold DESC, ProductID;

-- Product intelligence: highest rated, low sellers, and feedback trend.
SELECT ProductName, AverageRating, ReviewCount FROM v_ProductPerformance
WHERE ReviewCount > 0 ORDER BY AverageRating DESC, ReviewCount DESC, ProductID LIMIT 10;
SELECT ProductName, QuantitySold, Revenue, AverageRating FROM v_ProductPerformance
WHERE QuantitySold <= 1 ORDER BY QuantitySold, Revenue, ProductID;
SELECT DATE_FORMAT(ReviewDate, '%Y-%m') AS ReviewMonth, COUNT(*) AS Reviews,
       ROUND(AVG(Rating), 2) AS AverageRating,
       SUM(CASE WHEN Rating <= 2 THEN 1 ELSE 0 END) AS LowRatingReviews
FROM Reviews GROUP BY DATE_FORMAT(ReviewDate, '%Y-%m') ORDER BY ReviewMonth;

-- Automation and optimization checks.
CALL Generate_Sales_Report('2026-07-01', '2026-10-31');
SELECT Customer_Total_Spending(1) AS ArunLifetimeSpend, Product_Revenue(5) AS HeadphoneRevenue;
EXPLAIN SELECT ProductID, Name, Price FROM Product WHERE Name = 'Laptop';
EXPLAIN SELECT CustomerID FROM Customer WHERE Email = 'arun.raman@example.com';
EXPLAIN SELECT OrderID, OrderDate, TotalAmount FROM Orders
WHERE CustomerID = 1 ORDER BY OrderDate DESC LIMIT 10;
SHOW TRIGGERS;
