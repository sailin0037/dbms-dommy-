-- =================================================================
-- ShopSphere E-Commerce Retail Database System
-- Database Engine: MySQL 8.0+
-- Author: SRIRAM (ASML2520)
-- Description: Robust RDBMS implementing ACID properties, strict 
-- constraints, role-based boundaries, and analytical reporting.
-- =================================================================

DROP DATABASE IF EXISTS shopsphere_db;
CREATE DATABASE shopsphere_db;
USE shopsphere_db;

-- -----------------------------------------------------------------
-- 1. User & Account Management Domain
-- -----------------------------------------------------------------

-- Users Table (Implements Soft-Delete / Anonymization for Privacy Compliance)
CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    ContactNumber VARCHAR(15) NULL,
    RegistrationDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Role ENUM('Customer', 'Manager', 'Staff', 'Admin') NOT NULL,
    AccountStatus ENUM('Active', 'Inactive') NOT NULL DEFAULT 'Active'
);

-- Addresses Table (1:N Relationship with Users)
CREATE TABLE Addresses (
    AddressID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    AddressLine VARCHAR(255) NOT NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL,
    ZipCode VARCHAR(20) NOT NULL,
    IsDefault BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_addresses_users 
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
        ON UPDATE CASCADE
);

-- -----------------------------------------------------------------
-- 2. Product Catalog & Inventory Domain
-- -----------------------------------------------------------------

-- Categories Table
CREATE TABLE Categories (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE
);

-- Suppliers Table
CREATE TABLE Suppliers (
    SupplierID INT AUTO_INCREMENT PRIMARY KEY,
    SupplierName VARCHAR(150) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL
);

-- Products Table (Uses VARCHAR SKU as Primary Key)
CREATE TABLE Products (
    SKU VARCHAR(50) PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    StockQuantity INT NOT NULL CHECK (StockQuantity >= 0),
    CategoryID INT NOT NULL,
    SupplierID INT NULL,
    AvailabilityStatus ENUM('In Stock', 'Out of Stock', 'Discontinued') NOT NULL DEFAULT 'In Stock',
    CONSTRAINT fk_products_categories 
        FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    CONSTRAINT fk_products_suppliers 
        FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- Product Reviews Table
CREATE TABLE ProductReviews (
    ReviewID INT AUTO_INCREMENT PRIMARY KEY,
    SKU VARCHAR(50) NOT NULL,
    UserID INT NOT NULL,
    Rating INT NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
    ReviewText TEXT NULL,
    ReviewDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_products 
        FOREIGN KEY (SKU) REFERENCES Products(SKU) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_users 
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- -----------------------------------------------------------------
-- 3. Shopping Cart & Order Lifecycle Domain
-- -----------------------------------------------------------------

-- Orders Table (ON DELETE NO ACTION preserves financial audit logs)
CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    OrderDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(10,2) NOT NULL CHECK (TotalAmount > 0),
    Status ENUM('Pending', 'Payment Confirmed', 'Shipped', 'Delivered', 'Cancelled') NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_orders_users 
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
        ON UPDATE CASCADE ON DELETE NO ACTION
);

-- OrderItems Table (Bridging M:N relationship - Historic Price Rule enforced)
CREATE TABLE OrderItems (
    OrderID INT NOT NULL,
    SKU VARCHAR(50) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice > 0),
    PRIMARY KEY (OrderID, SKU),
    CONSTRAINT fk_orderitems_orders 
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT fk_orderitems_products 
        FOREIGN KEY (SKU) REFERENCES Products(SKU)
);

-- -----------------------------------------------------------------
-- 4. Payments & Shipping Operations Domain
-- -----------------------------------------------------------------

-- Payments Table (1:1 Relationship with Orders via UNIQUE constraint)
CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    PaymentMethod VARCHAR(50) NOT NULL,
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    PaymentStatus ENUM('Successful', 'Failed', 'Pending') NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_payments_orders 
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT uc_payments_orderid UNIQUE (OrderID)
);

-- Shipments Table (1:1 Relationship with Orders)
CREATE TABLE Shipments (
    ShipmentID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    TrackingNumber VARCHAR(100) NOT NULL UNIQUE,
    CarrierName VARCHAR(100) NOT NULL,
    ShipDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DeliveryDate TIMESTAMP NULL,
    CONSTRAINT fk_shipments_orders 
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT uc_shipments_orderid UNIQUE (OrderID)
);

-- AuditLogs Table (Tracks Admin actions to prevent internal fraud)
CREATE TABLE AuditLogs (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    AdminUserID INT NOT NULL,
    ActionType ENUM('CREATE', 'UPDATE', 'DELETE') NOT NULL,
    AffectedTable VARCHAR(100) NOT NULL,
    Timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditlogs_users 
        FOREIGN KEY (AdminUserID) REFERENCES Users(UserID)
);

-- -----------------------------------------------------------------
-- 5. Stored Procedures (ACID Concurrency & Safe Deletion)
-- -----------------------------------------------------------------

DELIMITER $$ 
-- Concurrency Control Mechanism (Row-Level Locking to prevent overselling)
CREATE PROCEDURE SafeCheckout(
    IN p_UserID INT, 
    IN p_SKU VARCHAR(50), 
    IN p_Quantity INT, 
    IN p_TotalAmount DECIMAL(10,2)
)
BEGIN
    DECLARE v_Stock INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Checkout failed. Transaction rolled back.';
    END;

    START TRANSACTION;
    
    -- Row-Level Lock to prevent race conditions
    SELECT StockQuantity INTO v_Stock 
    FROM Products 
    WHERE SKU = p_SKU 
    FOR UPDATE;
    
    IF v_Stock >= p_Quantity THEN
        -- Deduct inventory
        UPDATE Products 
        SET StockQuantity = StockQuantity - p_Quantity,
            AvailabilityStatus = IF(StockQuantity - p_Quantity = 0, 'Out of Stock', 'In Stock')
        WHERE SKU = p_SKU;
        
        -- Create Order
        INSERT INTO Orders (UserID, TotalAmount, Status) 
        VALUES (p_UserID, p_TotalAmount, 'Payment Confirmed');
        
        -- Link OrderItem with Historic Price
        INSERT INTO OrderItems (OrderID, SKU, Quantity, UnitPrice)
        VALUES (LAST_INSERT_ID(), p_SKU, p_Quantity, p_TotalAmount / p_Quantity);
        
        COMMIT;
    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock. Item is out of stock.';
    END IF;
END$$ 
-- Safe Deletion / Anonymization Procedure (Privacy Compliance)
CREATE PROCEDURE AnonymizeUser(IN p_UserID INT)
BEGIN
    UPDATE Users
    SET AccountStatus = 'Inactive',
        Email = CONCAT('anon_', p_UserID, '@null'),
        ContactNumber = NULL
    WHERE UserID = p_UserID;
END$$ 
DELIMITER ;

-- -----------------------------------------------------------------
-- 6. Sample Data Insertion (For Testing & Reports)
-- -----------------------------------------------------------------

INSERT INTO Users (Name, Email, PasswordHash, ContactNumber, Role) VALUES 
('Sriram', 'sriram@mail.com', 'hash123', '555-0100', 'Customer'),
('Alice', 'alice@mail.com', 'hash456', '555-0101', 'Customer'),
('Admin Bob', 'bob@mail.com', 'hash789', '555-0199', 'Admin');

INSERT INTO Categories (CategoryName) VALUES 
('Electronics'), 
('Apparel');

INSERT INTO Suppliers (SupplierName, ContactInfo) VALUES 
('Global Tech Supplies', 'sales@globaltech.com'),
('Fashion Wholesale', 'contact@fashionw.com');

INSERT INTO Products (SKU, ProductName, Price, StockQuantity, CategoryID, SupplierID) VALUES 
('PROD-001', '4K Ultra HD Smart TV', 499.00, 8, 1, 1),   -- Low stock
('PROD-002', 'Wireless Headphones', 59.99, 50, 1, 1),
('PROD-003', 'Cotton T-Shirt', 19.99, 5, 2, 2),          -- Low stock
('PROD-004', 'Gaming Laptop', 1199.50, 15, 1, 1);

-- Sample Orders, OrderItems, and Reviews to populate Reports 2 & 3
INSERT INTO Orders (UserID, OrderDate, TotalAmount, Status) VALUES 
(1, NOW(), 119.98, 'Delivered'),
(2, NOW(), 1199.50, 'Shipped');

INSERT INTO OrderItems (OrderID, SKU, Quantity, UnitPrice) VALUES 
(1, 'PROD-002', 2, 59.99),
(2, 'PROD-004', 1, 1199.50);

INSERT INTO ProductReviews (SKU, UserID, Rating, ReviewText) VALUES 
('PROD-002', 1, 5, 'Amazing sound quality!'),
('PROD-004', 2, 4, 'Very fast, but battery is average.');

-- -----------------------------------------------------------------
-- 7. Analytical Reports (As defined in RAD & DRD)
-- -----------------------------------------------------------------

-- REPORT 1: Low-Inventory Restock Alerts
-- Identifies products that need immediate restocking (<= 10 units)
SELECT 
    p.ProductName, 
    p.SKU, 
    c.CategoryName, 
    p.StockQuantity, 
    s.ContactInfo
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity <= 10 
  AND p.AvailabilityStatus != 'Discontinued';

-- REPORT 2: VIP Customer Loyalty Report
-- Top 50 customers by total spending in the last 12 months
SELECT 
    u.Name, 
    u.Email, 
    SUM(o.TotalAmount) AS TotalSpent
FROM Users u
INNER JOIN Orders o ON u.UserID = o.UserID
WHERE o.OrderDate >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
  AND o.Status IN ('Payment Confirmed', 'Shipped', 'Delivered')
GROUP BY u.UserID, u.Name, u.Email
ORDER BY TotalSpent DESC
LIMIT 50;

-- REPORT 3: Category Sales Performance Directory
-- Total revenue, items sold, and average rating per category
SELECT 
    c.CategoryName,
    SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue,
    SUM(oi.Quantity) AS ItemsSold,
    ROUND(AVG(pr.Rating), 2) AS AvgRating
FROM Categories c
INNER JOIN Products p ON c.CategoryID = p.CategoryID
INNER JOIN OrderItems oi ON p.SKU = oi.SKU
INNER JOIN Orders o ON oi.OrderID = o.OrderID
LEFT JOIN ProductReviews pr ON p.SKU = pr.SKU
GROUP BY c.CategoryID, c.CategoryName;

-- End of Script
