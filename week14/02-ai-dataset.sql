-- ShopSphere | Week 14 | The final grid is ready for CSV export in Workbench.
USE shopsphere_capstone;
SET @as_of_date = CAST('2026-11-01' AS DATE);

WITH KnownAges AS (
    SELECT CustomerID, TIMESTAMPDIFF(YEAR, DateOfBirth, @as_of_date) AS Age
    FROM Customer WHERE DateOfBirth <= @as_of_date
), AgeDefault AS (
    SELECT COALESCE(ROUND(AVG(Age)), 35) AS ImputedAge FROM KnownAges
), WindowOrders AS (
    SELECT OrderID, CustomerID, TotalAmount
    FROM v_PaidOrders
    WHERE OrderDate >= @as_of_date - INTERVAL 90 DAY AND OrderDate < @as_of_date
), OrderFeatures AS (
    SELECT CustomerID, COUNT(*) AS TotalPurchases, SUM(TotalAmount) AS TotalSpending,
           ROUND(AVG(TotalAmount), 2) AS AverageOrderValue
    FROM WindowOrders GROUP BY CustomerID
), CategoryUnits AS (
    SELECT w.CustomerID, p.CategoryID, SUM(oi.Quantity) AS Units
    FROM WindowOrders w JOIN v_PaidOrderItems oi ON oi.OrderID = w.OrderID
    JOIN Product p ON p.ProductID = oi.ProductID
    GROUP BY w.CustomerID, p.CategoryID
), RankedCategories AS (
    SELECT CustomerID, CategoryID,
           ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY Units DESC, CategoryID) AS Choice
    FROM CategoryUnits
)
SELECT c.CustomerID AS Customer_ID,
       COALESCE(a.Age, d.ImputedAge) AS Age,
       a.Age IS NULL AS Age_Was_Imputed,
       COALESCE(f.TotalPurchases, 0) AS Total_Purchases,
       COALESCE(f.TotalSpending, 0) AS Total_Spending,
       COALESCE(f.AverageOrderValue, 0) AS Average_Order_Value,
       ROUND(COALESCE(f.TotalPurchases, 0) / 3, 3) AS Purchase_Frequency,
       COALESCE(r.CategoryID, 0) AS Preferred_Category_ID,
       COALESCE(r.CategoryID = 1, 0) AS Pref_Electronics,
       COALESCE(r.CategoryID = 2, 0) AS Pref_Home_Kitchen,
       COALESCE(r.CategoryID = 3, 0) AS Pref_Office_Study,
       COALESCE(r.CategoryID = 4, 0) AS Pref_Sports_Travel,
       COALESCE(r.CategoryID = 5, 0) AS Pref_Apparel,
       r.CategoryID IS NULL AS Pref_None
FROM Customer c
CROSS JOIN AgeDefault d
LEFT JOIN KnownAges a ON a.CustomerID = c.CustomerID
LEFT JOIN OrderFeatures f ON f.CustomerID = c.CustomerID
LEFT JOIN RankedCategories r ON r.CustomerID = c.CustomerID AND r.Choice = 1
ORDER BY c.CustomerID;
