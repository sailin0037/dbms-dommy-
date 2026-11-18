-- ShopSphere | Week 15 | Reports and routines layered on the Week 12 and 14 objects.
USE shopsphere_capstone;

CREATE OR REPLACE VIEW v_CustomerOrderHistory AS
SELECT c.CustomerID, c.Name AS CustomerName, o.OrderID, o.OrderDate, o.TotalAmount,
       o.OrderStatus, pay.PaymentStatus
FROM Customer c JOIN Orders o ON o.CustomerID = c.CustomerID
LEFT JOIN Payment pay ON pay.OrderID = o.OrderID;

CREATE OR REPLACE VIEW v_SalesReport AS
SELECT DATE_FORMAT(OrderDate, '%Y-%m') AS SalesMonth, COUNT(*) AS Orders,
       SUM(TotalAmount) AS Revenue, ROUND(AVG(TotalAmount), 2) AS AverageOrderValue
FROM v_PaidOrders GROUP BY DATE_FORMAT(OrderDate, '%Y-%m');

CREATE OR REPLACE VIEW v_ProductPerformance AS
SELECT f.ProductID, f.Name AS ProductName, c.CategoryName, f.QuantitySold, f.Revenue,
       f.AverageRating, f.ReviewCount, f.AvailableStock
FROM v_ProductFeatures f JOIN Category c ON c.CategoryID = f.CategoryID;

DROP FUNCTION IF EXISTS Customer_Total_Spending;
DROP FUNCTION IF EXISTS Product_Revenue;
DROP PROCEDURE IF EXISTS Generate_Sales_Report;

DELIMITER $$

CREATE FUNCTION Customer_Total_Spending(p_customer INT)
RETURNS DECIMAL(18,2) READS SQL DATA
BEGIN
    RETURN (SELECT COALESCE(SUM(TotalAmount), 0)
            FROM v_PaidOrders WHERE CustomerID = p_customer);
END$$

CREATE FUNCTION Product_Revenue(p_product INT)
RETURNS DECIMAL(18,2) READS SQL DATA
BEGIN
    RETURN (SELECT COALESCE(SUM(LineRevenue), 0)
            FROM v_PaidOrderItems WHERE ProductID = p_product);
END$$

CREATE PROCEDURE Generate_Sales_Report(IN p_from DATE, IN p_through DATE)
BEGIN
    IF p_from IS NULL OR p_through IS NULL OR p_from > p_through THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Enter a valid date range';
    END IF;
    SELECT COUNT(*) AS Orders, COALESCE(SUM(TotalAmount), 0) AS Revenue,
           COALESCE(ROUND(AVG(TotalAmount), 2), 0) AS AverageOrderValue
    FROM v_PaidOrders
    WHERE OrderDate >= p_from AND OrderDate < p_through + INTERVAL 1 DAY;
END$$

DELIMITER ;
