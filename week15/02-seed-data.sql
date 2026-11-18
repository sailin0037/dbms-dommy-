-- ShopSphere | Week 15 | Seed once after week12/01-transactions.sql.
-- Fictional data. All prices and report amounts are INR.
USE shopsphere_capstone;

INSERT INTO Category (CategoryID, CategoryName) VALUES
    (1, 'Electronics'), (2, 'Home and Kitchen'), (3, 'Office and Study'),
    (4, 'Sports and Travel'), (5, 'Apparel');

INSERT INTO Seller (StoreName, ContactEmail, City) VALUES
    ('TechNova Solutions', 'sales@technova.example', 'Chennai'),
    ('ErgoComfort Supply', 'sales@ergocomfort.example', 'Coimbatore'),
    ('SecureLife Tech', 'sales@securelife.example', 'Bengaluru'),
    ('GadgetHub', 'sales@gadgethub.example', 'Hyderabad'),
    ('ByteStore', 'sales@bytestore.example', 'Chennai'),
    ('NextGen Electronics', 'sales@nextgen.example', 'Bengaluru'),
    ('HomeSmart', 'sales@homesmart.example', 'Madurai'),
    ('StreamWorks Gear', 'sales@streamworks.example', 'Kochi'),
    ('PowerGrid Tools', 'sales@powergrid.example', 'Pune'),
    ('Visionary Displays', 'sales@visionary.example', 'Hyderabad'),
    ('MobilityTech', 'sales@mobilitytech.example', 'Chennai'),
    ('AudioMax Direct', 'sales@audiomax.example', 'Pune'),
    ('PrintWorld India', 'sales@printworld.example', 'Coimbatore'),
    ('DataStore Systems', 'sales@datastore.example', 'Bengaluru'),
    ('SmartSecure', 'sales@smartsecure.example', 'Hyderabad'),
    ('Campus Desk', 'sales@campusdesk.example', 'Chennai'),
    ('Trail and Track', 'sales@trailandtrack.example', 'Kochi'),
    ('Cotton Coast', 'sales@cottoncoast.example', 'Tiruppur'),
    ('Peak Fitness', 'sales@peakfitness.example', 'Madurai'),
    ('Urban Threads', 'sales@urbanthreads.example', 'Tiruppur');

CREATE TEMPORARY TABLE seed_first_names (Number INT PRIMARY KEY, Name VARCHAR(20));
INSERT INTO seed_first_names VALUES
    (0, 'Arun'), (1, 'Priya'), (2, 'Kavya'), (3, 'Vikram'), (4, 'Meena'),
    (5, 'Karthik'), (6, 'Nila'), (7, 'Aditya'), (8, 'Ishani'), (9, 'Rahul');
CREATE TEMPORARY TABLE seed_last_names (Number INT PRIMARY KEY, Name VARCHAR(20), City VARCHAR(60));
INSERT INTO seed_last_names VALUES
    (0, 'Raman', 'Chennai'), (1, 'Iyer', 'Coimbatore'), (2, 'Nair', 'Kochi'),
    (3, 'Reddy', 'Hyderabad'), (4, 'Rao', 'Bengaluru');

INSERT INTO Customer (CustomerID, Name, Email, Phone, City, DateOfBirth)
SELECT 1 + f.Number + 10 * l.Number,
       CONCAT(f.Name, ' ', l.Name),
       LOWER(CONCAT(f.Name, '.', l.Name, '@example.com')),
       CONCAT('90000', LPAD(1 + f.Number + 10 * l.Number, 5, '0')),
       l.City,
       CASE WHEN MOD(f.Number + 10 * l.Number, 7) = 0 THEN NULL
            ELSE DATE_ADD('1972-01-01', INTERVAL ((f.Number + 10 * l.Number) * 257) DAY) END
FROM seed_first_names f CROSS JOIN seed_last_names l
ORDER BY 1;
DROP TEMPORARY TABLE seed_first_names, seed_last_names;

CREATE TEMPORARY TABLE seed_catalog (
    FamilyID INT PRIMARY KEY, CategoryID INT, Family VARCHAR(70), BasePrice DECIMAL(10,2)
);
INSERT INTO seed_catalog VALUES
    (1, 1, 'Laptop', 55000), (2, 1, 'Wireless Headphones', 2499),
    (3, 1, 'Portable SSD', 3999), (4, 1, 'Streaming Monitor', 12999),
    (5, 1, 'Mechanical Keyboard', 2799), (6, 2, 'Mixer Grinder', 4299),
    (7, 2, 'Induction Cooktop', 3499), (8, 2, 'Air Purifier', 6499),
    (9, 2, 'Electric Kettle', 1199), (10, 2, 'Storage Container Set', 699),
    (11, 3, 'Study Desk', 5999), (12, 3, 'Desk Lamp', 899),
    (13, 3, 'Office Chair', 5499), (14, 3, 'Document Organiser', 499),
    (15, 3, 'Notebook Set', 399), (16, 4, 'Yoga Mat', 899),
    (17, 4, 'Travel Backpack', 2499), (18, 4, 'Cricket Bat', 1799),
    (19, 4, 'Insulated Sports Bottle', 799), (20, 4, 'Cabin Suitcase', 3499),
    (21, 5, 'Cotton T-Shirt', 499), (22, 5, 'Running Shorts', 749),
    (23, 5, 'Linen Shirt', 1299), (24, 5, 'Hoodie', 1399),
    (25, 5, 'Crew Socks Pack', 399);
CREATE TEMPORARY TABLE seed_variants (Number INT PRIMARY KEY, Label VARCHAR(15), Multiplier DECIMAL(4,2));
INSERT INTO seed_variants VALUES (1, 'Classic', 1), (2, 'Plus', 1.12), (3, 'Pro', 1.28), (4, 'Max', 1.45);

INSERT INTO Product (ProductID, CategoryID, Name, Price)
SELECT (f.FamilyID - 1) * 4 + v.Number, f.CategoryID,
       CASE WHEN f.FamilyID = 1 AND v.Number = 1 THEN 'Laptop' ELSE CONCAT(f.Family, ' ', v.Label) END,
       ROUND(f.BasePrice * v.Multiplier, 0)
FROM seed_catalog f CROSS JOIN seed_variants v
ORDER BY 1;
DROP TEMPORARY TABLE seed_catalog, seed_variants;

INSERT INTO Inventory (InventoryID, ProductID, SellerID, SKU, StockQuantity, ReorderLevel)
SELECT ProductID, ProductID, 1 + MOD(ProductID - 1, 20),
       CASE WHEN ProductID = 1 THEN 'SS-LAP-001' ELSE CONCAT('SS-', LPAD(ProductID, 3, '0')) END,
       CASE WHEN ProductID = 1 THEN 10
            WHEN ProductID >= 96 THEN 6
            WHEN ProductID BETWEEN 91 AND 95 THEN 125
            ELSE 40 + MOD(ProductID * 13, 36) END,
       CASE WHEN ProductID >= 96 THEN 8 ELSE 5 END
FROM Product ORDER BY ProductID;

INSERT INTO Inventory (InventoryID, ProductID, SellerID, SKU, StockQuantity, ReorderLevel)
VALUES (101, 1, 4, 'SS-LAP-ALT', 15, 5), (102, 5, 12, 'SS-005-ALT', 90, 8),
       (103, 65, 17, 'SS-065-ALT', 25, 5);

DELIMITER $$
CREATE PROCEDURE SeedShopSphereOrders()
BEGIN
    DECLARE v_n INT DEFAULT 1;
    DECLARE v_order INT;
    DECLARE v_customer INT;
    DECLARE v_first INT;
    DECLARE v_second INT;
    DECLARE v_qty INT;
    DECLARE v_first_price DECIMAL(10,2);
    DECLARE v_second_price DECIMAL(10,2);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_date DATETIME;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    WHILE v_n <= 100 DO
        -- Frequent buyers and a concentrated bestseller make the reports meaningful.
        SET v_customer = CASE WHEN v_n <= 55 THEN v_n ELSE 1 + MOD(v_n * 7, 23) END;
        IF v_customer > 50 THEN
            SET v_customer = v_customer - 50;
        END IF;
        SET v_first = CASE WHEN MOD(v_n, 5) = 0 THEN 5 ELSE 2 + MOD(v_n * 17, 79) END;
        SET v_second = CASE WHEN MOD(v_n, 3) = 0 THEN 81 + MOD(v_n, 10) ELSE NULL END;
        SET v_qty = 1 + IF(MOD(v_n, 4) = 0, 1, 0);
        SET v_date = DATE_ADD('2026-07-01 10:00:00', INTERVAL (v_n + FLOOR(v_n / 5)) DAY);

        SELECT Price INTO v_first_price FROM Product WHERE ProductID = v_first;
        SET v_second_price = 0;
        IF v_second IS NOT NULL THEN
            SELECT Price INTO v_second_price FROM Product WHERE ProductID = v_second;
        END IF;
        SET v_total = v_qty * v_first_price + v_second_price;

        INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
        VALUES (v_customer, v_date, v_total);
        SET v_order = LAST_INSERT_ID();

        INSERT INTO OrderItems (OrderID, InventoryID, Quantity, PriceAtPurchase)
        VALUES (v_order, v_first, v_qty, v_first_price);
        IF v_second IS NOT NULL THEN
            INSERT INTO OrderItems (OrderID, InventoryID, Quantity, PriceAtPurchase)
            VALUES (v_order, v_second, 1, v_second_price);
        END IF;

        INSERT INTO Payment (OrderID, PaymentMethod, PaymentStatus, PaymentDate, AmountPaid)
        VALUES (v_order, ELT(1 + MOD(v_n, 5), 'UPI', 'Card', 'UPI', 'Net Banking', 'UPI'),
                'Success', v_date, v_total);
        SET v_n = v_n + 1;
    END WHILE;
    COMMIT;
END$$
DELIMITER ;

CALL SeedShopSphereOrders();
DROP PROCEDURE SeedShopSphereOrders;

INSERT INTO Reviews (ProductID, CustomerID, Rating, ReviewText, ReviewDate)
SELECT ranked.ProductID, ranked.CustomerID, ranked.Rating,
       ELT(ranked.Rating, 'Item needed replacement.', 'Usable but quality could improve.',
           'Good for the price.', 'Works as described.', 'Very happy with this purchase.'),
       DATE(ranked.OrderDate + INTERVAL 3 DAY)
FROM (
    SELECT oi.ProductID, oi.CustomerID, oi.OrderDate, oi.OrderID,
           1 + MOD(oi.CustomerID + oi.ProductID, 5) AS Rating,
           ROW_NUMBER() OVER (PARTITION BY oi.ProductID, oi.CustomerID ORDER BY oi.OrderID) AS ReviewChoice
    FROM v_PaidOrderItems oi
) AS ranked
WHERE ranked.ReviewChoice = 1
ORDER BY ranked.OrderID, ranked.ProductID LIMIT 50;

SELECT 'Customer' AS TableName, COUNT(*) AS RowCount FROM Customer
UNION ALL SELECT 'Product', COUNT(*) FROM Product
UNION ALL SELECT 'Seller', COUNT(*) FROM Seller
UNION ALL SELECT 'Inventory', COUNT(*) FROM Inventory
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'OrderItems', COUNT(*) FROM OrderItems
UNION ALL SELECT 'Payment', COUNT(*) FROM Payment
UNION ALL SELECT 'Reviews', COUNT(*) FROM Reviews;
