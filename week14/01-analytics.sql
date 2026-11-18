-- ShopSphere | Week 14 | Sales, customers, products, rankings and segmentation.
USE shopsphere_capstone;

CREATE OR REPLACE VIEW v_CustomerFeatures AS
SELECT c.CustomerID, c.Name, COUNT(o.OrderID) AS TotalPurchases,
       COALESCE(SUM(o.TotalAmount), 0) AS TotalSpending,
       COALESCE(ROUND(AVG(o.TotalAmount), 2), 0) AS AverageOrderValue,
       MAX(o.OrderDate) AS LastPurchaseDate
FROM Customer c LEFT JOIN v_PaidOrders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Name;

CREATE OR REPLACE VIEW v_CustomerSegmentation AS
SELECT CustomerID, Name, TotalPurchases, TotalSpending,
       CASE WHEN TotalPurchases >= 3 AND TotalSpending >= 25000 THEN 'Premium'
            WHEN TotalPurchases >= 2 OR TotalSpending >= 8000 THEN 'Regular'
            ELSE 'Low value' END AS Segment
FROM v_CustomerFeatures;

CREATE OR REPLACE VIEW v_ProductFeatures AS
SELECT p.ProductID, p.Name, p.CategoryID,
       COALESCE(s.QuantitySold, 0) AS QuantitySold,
       COALESCE(s.Revenue, 0) AS Revenue,
       r.AverageRating, COALESCE(r.ReviewCount, 0) AS ReviewCount,
       COALESCE(i.AvailableStock, 0) AS AvailableStock
FROM Product p
LEFT JOIN (SELECT ProductID, SUM(Quantity) AS QuantitySold, SUM(LineRevenue) AS Revenue
           FROM v_PaidOrderItems GROUP BY ProductID) s ON s.ProductID = p.ProductID
LEFT JOIN (SELECT ProductID, ROUND(AVG(Rating), 2) AS AverageRating, COUNT(*) AS ReviewCount
           FROM Reviews GROUP BY ProductID) r ON r.ProductID = p.ProductID
LEFT JOIN (SELECT ProductID, SUM(StockQuantity) AS AvailableStock
           FROM Inventory GROUP BY ProductID) i ON i.ProductID = p.ProductID;

-- Sales performance and month-by-month revenue.
SELECT COALESCE(SUM(TotalAmount), 0) AS TotalSales, COUNT(*) AS NumberOfOrders,
       COALESCE(ROUND(AVG(TotalAmount), 2), 0) AS AverageOrderValue
FROM v_PaidOrders;
SELECT DATE_FORMAT(OrderDate, '%Y-%m') AS SalesMonth, COUNT(*) AS NumberOfOrders,
       SUM(TotalAmount) AS MonthlyRevenue, ROUND(AVG(TotalAmount), 2) AS AverageOrderValue
FROM v_PaidOrders GROUP BY DATE_FORMAT(OrderDate, '%Y-%m') ORDER BY SalesMonth;

-- Customer analysis and spending rank (tied ranks are consecutive).
SELECT Name AS CustomerName, TotalSpending, TotalPurchases AS NumberOfOrders,
       AverageOrderValue, LastPurchaseDate,
       DENSE_RANK() OVER (ORDER BY TotalSpending DESC) AS SpendingRank
FROM v_CustomerFeatures ORDER BY SpendingRank, CustomerID;

-- Product performance and sales rank (ties share a rank and leave a gap).
SELECT Name AS ProductName, QuantitySold, Revenue, AverageRating, ReviewCount, AvailableStock,
       RANK() OVER (ORDER BY QuantitySold DESC) AS SalesRank
FROM v_ProductFeatures ORDER BY SalesRank, Revenue DESC, ProductID;

-- Latest order sequence per customer. OrderID breaks ties on the timestamp.
SELECT CustomerID, OrderID, OrderDate,
       ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS LatestOrderNumber
FROM v_PaidOrders ORDER BY CustomerID, LatestOrderNumber;

-- Segmentation report and segment totals.
SELECT Name, Segment, TotalPurchases AS LifetimePurchaseCount, TotalSpending
FROM v_CustomerSegmentation ORDER BY TotalSpending DESC, CustomerID;
SELECT Segment, COUNT(*) AS Customers, SUM(TotalPurchases) AS Orders, SUM(TotalSpending) AS Revenue
FROM v_CustomerSegmentation GROUP BY Segment ORDER BY Revenue DESC;

-- Time-based features from completed purchases.
SELECT YEAR(OrderDate) AS PurchaseYear, MONTH(OrderDate) AS PurchaseMonth,
       DAY(OrderDate) AS PurchaseDay, COUNT(*) AS Purchases
FROM v_PaidOrders
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DAY(OrderDate)
ORDER BY PurchaseYear, PurchaseMonth, PurchaseDay;
