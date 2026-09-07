-- ============================================================
-- WEEK 6: PRODUCT REVIEW & RATING MANAGEMENT SYSTEM
-- WEEK 7: SQL QUERY IMPLEMENTATION
-- ============================================================

USE shopsphere_db;   -- fixes Error 1046 "No database selected"

-- (Optional diagnostics: run these to see your real table structures)
-- SHOW TABLES;
-- DESCRIBE users;
-- DESCRIBE products;

-- WARNING: this recreates Customers/Products (their data is cleared).
-- If your existing products table has data you need, use Option B at the bottom.
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- TASK 1 & 2: CREATE TABLES + RELATIONSHIPS + CONSTRAINTS
-- Customer (1)----(Many) Review
-- Product  (1)----(Many) Review
-- ============================================================

CREATE TABLE Customers (
    Customer_ID   INT PRIMARY KEY AUTO_INCREMENT,
    Customer_Name VARCHAR(100) NOT NULL,
    Email         VARCHAR(100) UNIQUE,
    City          VARCHAR(50),
    Phone         VARCHAR(15)
);

CREATE TABLE Products (
    Product_ID   INT PRIMARY KEY AUTO_INCREMENT,
    Product_Name VARCHAR(100) NOT NULL,
    Category     VARCHAR(50),
    Price        DECIMAL(10,2) CHECK (Price >= 0),
    Stock        INT DEFAULT 0
);

CREATE TABLE Reviews (
    Review_ID   INT PRIMARY KEY AUTO_INCREMENT,          -- Primary Key
    Customer_ID INT NOT NULL,                            -- Foreign Key
    Product_ID  INT NOT NULL,                            -- Foreign Key
    Rating      INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),  -- CHECK constraint
    Review_Text VARCHAR(500),
    Review_Date DATE NOT NULL,                           -- NOT NULL
    CONSTRAINT fk_rev_customer FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
    CONSTRAINT fk_rev_product  FOREIGN KEY (Product_ID)  REFERENCES Products(Product_ID)
);

-- ============================================================
-- TASK 3: STORE CUSTOMER FEEDBACK AND RATINGS
-- ============================================================

INSERT INTO Customers (Customer_Name, Email, City, Phone) VALUES
('John',   'john@mail.com',   'Chennai', '9876500001'),
('Priya',  'priya@mail.com',  'Mumbai',  '9876500002'),
('Arun',   'arun@mail.com',   'Delhi',   '9876500003'),
('Sneha',  'sneha@mail.com',  'Chennai', '9876500004'),
('Vikram', 'vikram@mail.com', 'Pune',    '9876500005');

INSERT INTO Products (Product_Name, Category, Price, Stock) VALUES
('Laptop',      'Electronics', 55000.00, 10),
('Mobile',      'Electronics', 18000.00, 25),
('Headphones',  'Electronics',  2500.00, 50),
('Smart Watch', 'Electronics',  8000.00, 15),
('Keyboard',    'Accessories',  1200.00, 40),
('Mouse',       'Accessories',   800.00, 60);

-- Example data from the document (R101 John/Laptop/5, R102 Priya/Mobile/4)
INSERT INTO Reviews (Customer_ID, Product_ID, Rating, Review_Text, Review_Date) VALUES
(1, 1, 5, 'Excellent performance',        '2025-06-01'),
(2, 2, 4, 'Good battery life',            '2025-06-02'),
(1, 3, 3, 'Average sound quality',        '2025-06-03'),
(3, 1, 4, 'Value for money',              '2025-06-04'),
(4, 1, 5, 'Best laptop I have used',      '2025-06-05'),
(5, 2, 2, 'Camera quality is poor',       '2025-06-06'),
(2, 3, 5, 'Great noise cancellation',     '2025-06-07'),
(4, 4, 4, 'Nice features',                '2025-06-08'),
(5, 6, 1, 'Stopped working in a week',    '2025-06-09'),
(3, 5, 5, 'Very smooth typing',           '2025-06-10');

-- 3.3 Update a review comment
UPDATE Reviews
SET Review_Text = 'Excellent performance, great build quality'
WHERE Review_ID = 1;

-- 3.4 Remove an inappropriate review
INSERT INTO Reviews (Customer_ID, Product_ID, Rating, Review_Text, Review_Date)
VALUES (5, 1, 1, 'SPAM LINK www.spamsite.com', '2025-06-11');

DELETE FROM Reviews WHERE Review_Text LIKE '%SPAM%';

-- ============================================================
-- TASK 4: RETRIEVE PRODUCT REVIEW DETAILS
-- ============================================================

-- 1. Display all reviews for a product
SELECT r.Review_ID, c.Customer_Name, p.Product_Name, r.Rating, r.Review_Text, r.Review_Date
FROM Reviews r
JOIN Customers c ON r.Customer_ID = c.Customer_ID
JOIN Products  p ON r.Product_ID  = p.Product_ID
WHERE p.Product_Name = 'Laptop';

-- 2. Display customer name with their reviews
SELECT c.Customer_Name, p.Product_Name, r.Rating, r.Review_Text
FROM Customers c
JOIN Reviews r ON c.Customer_ID = r.Customer_ID
JOIN Products p ON r.Product_ID = p.Product_ID;

-- 3. Find products having maximum reviews
SELECT p.Product_Name, COUNT(r.Review_ID) AS Total_Reviews
FROM Products p
JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING COUNT(r.Review_ID) = (
    SELECT MAX(total) FROM (SELECT COUNT(*) AS total FROM Reviews GROUP BY Product_ID) x
);

-- 4. Display recent customer feedback
SELECT c.Customer_Name, p.Product_Name, r.Rating, r.Review_Text, r.Review_Date
FROM Reviews r
JOIN Customers c ON r.Customer_ID = c.Customer_ID
JOIN Products  p ON r.Product_ID  = p.Product_ID
ORDER BY r.Review_Date DESC
LIMIT 5;

-- 5. Retrieve reviews with ratings above 4
SELECT * FROM Reviews WHERE Rating > 4;

-- ============================================================
-- TASK 5: CALCULATE AVERAGE PRODUCT RATINGS
-- ============================================================

-- 1. Average rating for each product
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Products p
JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name;

-- 2. Count the number of reviews per product
SELECT p.Product_Name, COUNT(r.Review_ID) AS Review_Count
FROM Products p
JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name;

-- 3. Find highest-rated products
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Products p
JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name
ORDER BY Avg_Rating DESC
LIMIT 3;

-- 4. Products with average rating above 4
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Products p
JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name
HAVING AVG(r.Rating) > 4;

-- ============================================================
-- TASK 6: REPORTS
-- ============================================================

-- REPORT 1: Product Rating Analysis (name, review count, avg rating)
SELECT p.Product_Name,
       COUNT(r.Review_ID)      AS Number_of_Reviews,
       ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Products p
LEFT JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name
ORDER BY Average_Rating DESC;

-- REPORT 2: Customer Feedback Analysis
-- a) Most reviewed products
SELECT p.Product_Name, COUNT(r.Review_ID) AS Total_Reviews
FROM Products p JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name
ORDER BY Total_Reviews DESC;

-- b) Highly rated products (avg >= 4)
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Products p JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name
HAVING AVG(r.Rating) >= 4;

-- c) Products requiring improvement (avg < 3)
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Products p JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_Name
HAVING AVG(r.Rating) < 3;

-- REPORT 3: Rating Distribution
-- a) Summary counts
SELECT
  SUM(CASE WHEN Rating = 5   THEN 1 ELSE 0 END) AS Five_Star_Ratings,
  SUM(CASE WHEN Rating = 4   THEN 1 ELSE 0 END) AS Four_Star_Ratings,
  SUM(CASE WHEN Rating <= 2  THEN 1 ELSE 0 END) AS Low_Rated_Reviews
FROM Reviews;

-- b) Per-star breakdown
SELECT Rating, COUNT(*) AS Number_of_Reviews
FROM Reviews
GROUP BY Rating
ORDER BY Rating DESC;

-- ============================================================
-- WEEK 7: BASIC SELECT + WHERE QUERIES
-- ============================================================

-- 1. Display all customer details
SELECT * FROM Customers;

-- 2. Display all available products
SELECT * FROM Products WHERE Stock > 0;

-- 3. Retrieve product names and prices only
SELECT Product_Name, Price FROM Products;

-- 4. Display all orders placed by customers (uses your existing orders table)
SELECT * FROM orders;

-- 5. Retrieve payment details (uses your existing payments table)
SELECT * FROM payments;

-- WHERE filters
SELECT * FROM Products WHERE Price > 5000;              -- price > 5000
SELECT * FROM Products WHERE Stock > 0;                 -- available in stock
SELECT * FROM Customers WHERE City = 'Chennai';         -- customers from a city
SELECT * FROM orders WHERE status = 'Completed';        -- completed orders (adjust column if needed)