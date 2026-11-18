-- ShopSphere | Week 15 | Unified schema for Weeks 12–15
CREATE DATABASE IF NOT EXISTS shopsphere_capstone CHARACTER SET utf8mb4;
USE shopsphere_capstone;

CREATE TABLE Customer (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL,
    Phone VARCHAR(20),
    City VARCHAR(60) NOT NULL,
    DateOfBirth DATE,
    CONSTRAINT uq_customer_email UNIQUE (Email)
) ENGINE = InnoDB;

CREATE TABLE Category (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(80) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE Seller (
    SellerID INT AUTO_INCREMENT PRIMARY KEY,
    StoreName VARCHAR(100) NOT NULL UNIQUE,
    ContactEmail VARCHAR(150) NOT NULL UNIQUE,
    City VARCHAR(60) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE Product (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryID INT NOT NULL,
    Name VARCHAR(120) NOT NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    KEY ix_product_category_fk (CategoryID),
    FOREIGN KEY (CategoryID) REFERENCES Category (CategoryID)
) ENGINE = InnoDB;

CREATE TABLE Inventory (
    InventoryID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    SellerID INT NOT NULL,
    SKU VARCHAR(40) NOT NULL UNIQUE,
    StockQuantity INT NOT NULL CHECK (StockQuantity >= 0),
    ReorderLevel INT NOT NULL DEFAULT 5 CHECK (ReorderLevel >= 0),
    UNIQUE (ProductID, SellerID),
    FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
    FOREIGN KEY (SellerID) REFERENCES Seller (SellerID)
) ENGINE = InnoDB;

CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(12,2) NOT NULL CHECK (TotalAmount > 0),
    OrderStatus ENUM('Pending', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customer (CustomerID)
) ENGINE = InnoDB;

CREATE TABLE OrderItems (
    OrderItemID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    InventoryID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PriceAtPurchase DECIMAL(10,2) NOT NULL CHECK (PriceAtPurchase > 0),
    UNIQUE (OrderID, InventoryID),
    FOREIGN KEY (OrderID) REFERENCES Orders (OrderID),
    FOREIGN KEY (InventoryID) REFERENCES Inventory (InventoryID)
) ENGINE = InnoDB;

CREATE TABLE Payment (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE,
    PaymentMethod ENUM('UPI', 'Card', 'Net Banking', 'Cash on Delivery') NOT NULL,
    PaymentStatus ENUM('Success', 'Failed', 'Pending') NOT NULL,
    PaymentDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    AmountPaid DECIMAL(12,2) NOT NULL CHECK (AmountPaid >= 0),
    CHECK ((PaymentStatus = 'Success' AND AmountPaid > 0)
        OR (PaymentStatus <> 'Success' AND AmountPaid = 0)),
    FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
) ENGINE = InnoDB;

CREATE TABLE Reviews (
    ReviewID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating TINYINT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    ReviewText VARCHAR(300),
    ReviewDate DATE NOT NULL,
    UNIQUE (ProductID, CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customer (CustomerID)
) ENGINE = InnoDB;

CREATE TABLE InventoryMovement (
    MovementID BIGINT AUTO_INCREMENT PRIMARY KEY,
    InventoryID INT NOT NULL,
    OrderID INT,
    MovementType ENUM('Sale', 'Restock') NOT NULL,
    PreviousStock INT NOT NULL CHECK (PreviousStock >= 0),
    CurrentStock INT NOT NULL CHECK (CurrentStock >= 0),
    RecordedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK ((MovementType = 'Sale' AND OrderID IS NOT NULL AND CurrentStock < PreviousStock)
        OR (MovementType = 'Restock' AND OrderID IS NULL AND CurrentStock > PreviousStock)),
    FOREIGN KEY (InventoryID) REFERENCES Inventory (InventoryID),
    FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
) ENGINE = InnoDB;

CREATE TABLE CheckoutFailure (
    FailureID BIGINT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    InventoryID INT NOT NULL,
    AttemptedOrderID INT NOT NULL,
    PaymentMethod ENUM('UPI', 'Card', 'Net Banking', 'Cash on Delivery') NOT NULL,
    RequestedQuantity INT NOT NULL CHECK (RequestedQuantity > 0),
    StockBefore INT NOT NULL CHECK (StockBefore >= 0),
    StockAfterRollback INT NOT NULL,
    FailureReason VARCHAR(150) NOT NULL,
    AttemptedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (StockAfterRollback = StockBefore),
    FOREIGN KEY (CustomerID) REFERENCES Customer (CustomerID),
    FOREIGN KEY (InventoryID) REFERENCES Inventory (InventoryID)
) ENGINE = InnoDB;
