-- ShopSphere | Week 12 | Run after the schema, Week 12 setup, and Week 15 seed.
USE shopsphere_capstone;
SET @demo_sku = 'SS-LAP-001';
SELECT StockQuantity INTO @stock_before FROM Inventory WHERE SKU = @demo_sku;

-- 1. Successful UPI purchase. Expected first run: 55000.00, Completed, Success.
CALL PlaceOrder(1, @demo_sku, 1, 'UPI', TRUE, @paid_order, @no_failure);
SELECT StockQuantity INTO @stock_after_commit FROM Inventory WHERE SKU = @demo_sku;

-- 2. Failed UPI payment. The order, line, payment and stock movement roll back.
CALL PlaceOrder(2, @demo_sku, 1, 'UPI', FALSE, @no_order, @declined_attempt);
SELECT StockQuantity INTO @stock_after_rollback FROM Inventory WHERE SKU = @demo_sku;

-- Report 1: Order transaction report.
SELECT o.OrderID, c.Name AS CustomerName, o.TotalAmount AS Amount,
       pay.PaymentMethod, pay.PaymentStatus, o.OrderStatus
FROM Orders o
JOIN Customer c ON c.CustomerID = o.CustomerID
LEFT JOIN Payment pay ON pay.OrderID = o.OrderID
WHERE o.OrderID = @paid_order;

-- Report 2: Failed transaction report.
SELECT f.AttemptedOrderID, c.Name AS CustomerName, p.Name AS ProductName,
       f.PaymentMethod, 'Failed' AS PaymentStatus, 'Cancelled (rolled back)' AS OrderStatus,
       f.FailureReason, f.StockBefore, f.StockAfterRollback,
       f.RequestedQuantity AS UnitsRestored
FROM CheckoutFailure f
JOIN Customer c ON c.CustomerID = f.CustomerID
JOIN Inventory i ON i.InventoryID = f.InventoryID
JOIN Product p ON p.ProductID = i.ProductID
WHERE f.FailureID = @declined_attempt;

-- Report 3: Inventory update report for the committed order.
SELECT p.Name AS ProductName, i.SKU, m.PreviousStock, m.CurrentStock,
       m.PreviousStock - m.CurrentStock AS QuantitySold
FROM InventoryMovement m
JOIN Inventory i ON i.InventoryID = m.InventoryID
JOIN Product p ON p.ProductID = i.ProductID
WHERE m.OrderID = @paid_order;

SELECT @stock_before AS StockBefore, @stock_after_commit AS AfterCommit,
       @stock_after_rollback AS AfterRollback,
       @stock_after_commit = @stock_before - 1 AS CommitCheck,
       @stock_after_rollback = @stock_after_commit AS RollbackCheck;

-- 3. Integrity checks. Each violation count should be zero.
SELECT 'Orders without a valid customer' AS IntegrityCheck, COUNT(*) AS Violations
FROM Orders o LEFT JOIN Customer c ON c.CustomerID = o.CustomerID WHERE c.CustomerID IS NULL
UNION ALL
SELECT 'Payments without a valid order', COUNT(*)
FROM Payment pay LEFT JOIN Orders o ON o.OrderID = pay.OrderID WHERE o.OrderID IS NULL
UNION ALL
SELECT 'Negative inventory stock', COUNT(*) FROM Inventory WHERE StockQuantity < 0
UNION ALL
SELECT 'Completed orders without a matching successful payment', COUNT(*)
FROM Orders o LEFT JOIN Payment pay ON pay.OrderID = o.OrderID
    AND pay.PaymentStatus = 'Success' AND pay.AmountPaid = o.TotalAmount
WHERE o.OrderStatus = 'Completed' AND pay.PaymentID IS NULL
UNION ALL
SELECT 'Cancelled orders with a stock deduction', COUNT(*)
FROM Orders o JOIN InventoryMovement m ON m.OrderID = o.OrderID
WHERE o.OrderStatus = 'Cancelled' AND m.MovementType = 'Sale'
UNION ALL
SELECT 'Declined checkouts with remaining order, item, payment or stock movement', COUNT(*)
FROM CheckoutFailure f
WHERE EXISTS (SELECT 1 FROM Orders WHERE OrderID = f.AttemptedOrderID)
   OR EXISTS (SELECT 1 FROM OrderItems WHERE OrderID = f.AttemptedOrderID)
   OR EXISTS (SELECT 1 FROM Payment WHERE OrderID = f.AttemptedOrderID)
   OR EXISTS (SELECT 1 FROM InventoryMovement WHERE OrderID = f.AttemptedOrderID);

-- Optional negative test: select and run separately in Workbench. Expect SQLSTATE 45000.
-- CALL PlaceOrder(1, 'SS-LAP-001', 999999, 'UPI', TRUE, @order_id, @failure_id);
