-- ShopSphere | Week 13 | Run once after the seed. Copy actual elapsed times from EXPLAIN ANALYZE.
USE shopsphere_capstone;

SELECT 'Before adding search indexes' AS Phase;
EXPLAIN ANALYZE SELECT ProductID, Name, Price FROM Product WHERE Name = 'Laptop';
EXPLAIN ANALYZE SELECT ProductID, Name FROM Product WHERE CategoryID = 1 ORDER BY Name;
EXPLAIN ANALYZE SELECT CustomerID FROM Customer WHERE Email = 'arun.raman@example.com';
EXPLAIN ANALYZE SELECT CustomerID FROM Customer WHERE Phone = '9000000001';
EXPLAIN ANALYZE SELECT OrderID, OrderDate, TotalAmount FROM Orders
WHERE CustomerID = 1 ORDER BY OrderDate DESC LIMIT 10;
EXPLAIN ANALYZE SELECT COUNT(*) AS Orders, SUM(TotalAmount) AS Revenue FROM v_PaidOrders
WHERE OrderDate >= '2026-09-01' AND OrderDate < '2026-10-01';
EXPLAIN ANALYZE SELECT ProductID, SUM(Quantity) AS UnitsSold FROM v_PaidOrderItems
WHERE OrderDate >= '2026-09-01' AND OrderDate < '2026-10-01'
GROUP BY ProductID ORDER BY UnitsSold DESC, ProductID LIMIT 5;

CREATE INDEX ix_product_name ON Product (Name);
CREATE INDEX ix_product_category_name ON Product (CategoryID, Name);
-- Email already has a unique index named uq_customer_email.
CREATE INDEX ix_customer_phone ON Customer (Phone);
CREATE INDEX ix_orders_date ON Orders (OrderDate);
CREATE INDEX ix_orders_customer_date ON Orders (CustomerID, OrderDate);
ANALYZE TABLE Product, Customer, Orders, OrderItems, Payment;

SELECT 'After adding search indexes' AS Phase;
EXPLAIN ANALYZE SELECT ProductID, Name, Price FROM Product WHERE Name = 'Laptop';
EXPLAIN ANALYZE SELECT ProductID, Name FROM Product WHERE CategoryID = 1 ORDER BY Name;
EXPLAIN ANALYZE SELECT CustomerID FROM Customer WHERE Email = 'arun.raman@example.com';
EXPLAIN ANALYZE SELECT CustomerID FROM Customer WHERE Phone = '9000000001';
EXPLAIN ANALYZE SELECT OrderID, OrderDate, TotalAmount FROM Orders
WHERE CustomerID = 1 ORDER BY OrderDate DESC LIMIT 10;
EXPLAIN ANALYZE SELECT COUNT(*) AS Orders, SUM(TotalAmount) AS Revenue FROM v_PaidOrders
WHERE OrderDate >= '2026-09-01' AND OrderDate < '2026-10-01';
EXPLAIN ANALYZE SELECT ProductID, SUM(Quantity) AS UnitsSold FROM v_PaidOrderItems
WHERE OrderDate >= '2026-09-01' AND OrderDate < '2026-10-01'
GROUP BY ProductID ORDER BY UnitsSold DESC, ProductID LIMIT 5;

-- Standard EXPLAIN makes the selected key visible in Workbench's grid.
EXPLAIN SELECT ProductID, Name, Price FROM Product WHERE Name = 'Laptop';
SHOW INDEX FROM Product;
SHOW INDEX FROM Customer;
SHOW INDEX FROM Orders;
