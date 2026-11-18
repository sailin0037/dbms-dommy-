-- ShopSphere | Week 13 | Run as the local MySQL root/DBA after Week 12 setup.
-- The four generated passwords appear in the result grids on first creation.
USE shopsphere_capstone;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_SalesOrderSummary AS
SELECT OrderID, CustomerID, OrderDate, TotalAmount, OrderStatus FROM Orders;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_SalesMonthlyReport AS
SELECT DATE_FORMAT(OrderDate, '%Y-%m') AS SalesMonth, COUNT(*) AS Orders,
       SUM(TotalAmount) AS Revenue
FROM v_PaidOrders GROUP BY DATE_FORMAT(OrderDate, '%Y-%m');

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_InventoryStaffStock AS
SELECT i.SKU, p.Name AS ProductName, i.StockQuantity, i.ReorderLevel
FROM Inventory i JOIN Product p ON p.ProductID = i.ProductID;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_SupportCustomer AS
SELECT CustomerID, Name, Email, Phone, City FROM Customer;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_SupportOrder AS
SELECT OrderID, CustomerID, OrderDate, OrderStatus FROM Orders;

CREATE ROLE IF NOT EXISTS 'ss_admin_role', 'ss_sales_role', 'ss_inventory_role', 'ss_support_role';
CREATE USER IF NOT EXISTS 'ss_admin'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
CREATE USER IF NOT EXISTS 'ss_sales'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
CREATE USER IF NOT EXISTS 'ss_inventory'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
CREATE USER IF NOT EXISTS 'ss_support'@'localhost' IDENTIFIED BY RANDOM PASSWORD;

GRANT ALL PRIVILEGES ON shopsphere_capstone.* TO 'ss_admin_role' WITH GRANT OPTION;
GRANT CREATE USER ON *.* TO 'ss_admin_role';

GRANT SELECT ON shopsphere_capstone.Orders TO 'ss_sales_role';
GRANT SELECT ON shopsphere_capstone.v_SalesOrderSummary TO 'ss_sales_role';
GRANT SELECT ON shopsphere_capstone.v_SalesMonthlyReport TO 'ss_sales_role';

GRANT SELECT ON shopsphere_capstone.v_InventoryStaffStock TO 'ss_inventory_role';
GRANT EXECUTE ON PROCEDURE shopsphere_capstone.AddStock TO 'ss_inventory_role';

GRANT SELECT ON shopsphere_capstone.v_SupportCustomer TO 'ss_support_role';
GRANT SELECT ON shopsphere_capstone.v_SupportOrder TO 'ss_support_role';

GRANT 'ss_admin_role', 'ss_sales_role', 'ss_inventory_role', 'ss_support_role'
TO 'ss_admin'@'localhost' WITH ADMIN OPTION;
GRANT 'ss_sales_role' TO 'ss_sales'@'localhost';
GRANT 'ss_inventory_role' TO 'ss_inventory'@'localhost';
GRANT 'ss_support_role' TO 'ss_support'@'localhost';
SET DEFAULT ROLE 'ss_admin_role' TO 'ss_admin'@'localhost';
SET DEFAULT ROLE 'ss_sales_role' TO 'ss_sales'@'localhost';
SET DEFAULT ROLE 'ss_inventory_role' TO 'ss_inventory'@'localhost';
SET DEFAULT ROLE 'ss_support_role' TO 'ss_support'@'localhost';

-- GRANT/REVOKE demonstration. Execute this part while the lab users are idle.
GRANT INSERT ON shopsphere_capstone.Payment TO 'ss_sales'@'localhost';
SHOW GRANTS FOR 'ss_sales'@'localhost' USING 'ss_sales_role';
REVOKE INSERT ON shopsphere_capstone.Payment FROM 'ss_sales'@'localhost';

-- User access and security reports. USING expands privileges inherited from roles.
SHOW GRANTS FOR 'ss_admin'@'localhost' USING 'ss_admin_role';
SHOW GRANTS FOR 'ss_sales'@'localhost' USING 'ss_sales_role';
SHOW GRANTS FOR 'ss_inventory'@'localhost' USING 'ss_inventory_role';
SHOW GRANTS FOR 'ss_support'@'localhost' USING 'ss_support_role';
