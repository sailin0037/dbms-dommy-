-- ShopSphere | Week 12 | Install after week15/01-schema.sql.
USE shopsphere_capstone;

CREATE OR REPLACE VIEW v_PaidOrders AS
SELECT o.OrderID, o.CustomerID, o.OrderDate, o.TotalAmount, pay.PaymentMethod
FROM Orders o
JOIN Payment pay ON pay.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed' AND pay.PaymentStatus = 'Success';

CREATE OR REPLACE VIEW v_PaidOrderItems AS
SELECT o.OrderID, o.CustomerID, o.OrderDate, i.ProductID, i.SellerID,
       oi.InventoryID, oi.Quantity, oi.PriceAtPurchase,
       oi.Quantity * oi.PriceAtPurchase AS LineRevenue
FROM v_PaidOrders o
JOIN OrderItems oi ON oi.OrderID = o.OrderID
JOIN Inventory i ON i.InventoryID = oi.InventoryID;

DROP TRIGGER IF EXISTS trg_orderitem_stock;
DROP TRIGGER IF EXISTS trg_payment_complete;
DROP TRIGGER IF EXISTS trg_order_cancellation;
DROP PROCEDURE IF EXISTS PlaceOrder;
DROP PROCEDURE IF EXISTS AddStock;

DELIMITER $$

CREATE TRIGGER trg_orderitem_stock AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    DECLARE v_stock INT DEFAULT NULL;
    DECLARE v_status VARCHAR(12) DEFAULT NULL;

    SELECT OrderStatus INTO v_status FROM Orders WHERE OrderID = NEW.OrderID;
    IF v_status IS NULL OR v_status <> 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only pending orders accept items';
    END IF;

    SELECT StockQuantity INTO v_stock
    FROM Inventory WHERE InventoryID = NEW.InventoryID FOR UPDATE;

    IF v_stock IS NULL OR v_stock < NEW.Quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient inventory stock';
    END IF;

    UPDATE Inventory SET StockQuantity = v_stock - NEW.Quantity
    WHERE InventoryID = NEW.InventoryID;

    INSERT INTO InventoryMovement
        (InventoryID, OrderID, MovementType, PreviousStock, CurrentStock)
    VALUES (NEW.InventoryID, NEW.OrderID, 'Sale', v_stock, v_stock - NEW.Quantity);
END$$

CREATE TRIGGER trg_order_cancellation BEFORE UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.OrderStatus = 'Cancelled' AND OLD.OrderStatus <> 'Cancelled' AND (
        EXISTS (SELECT 1 FROM InventoryMovement WHERE OrderID = OLD.OrderID)
        OR EXISTS (SELECT 1 FROM Payment WHERE OrderID = OLD.OrderID AND PaymentStatus = 'Success')
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rollback the checkout or use a returns workflow';
    END IF;
END$$

CREATE TRIGGER trg_payment_complete AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_status VARCHAR(12);
    DECLARE v_lines DECIMAL(12,2);

    IF NEW.PaymentStatus = 'Success' THEN
        SELECT TotalAmount, OrderStatus INTO v_total, v_status
        FROM Orders WHERE OrderID = NEW.OrderID;
        SELECT COALESCE(SUM(Quantity * PriceAtPurchase), 0) INTO v_lines
        FROM OrderItems WHERE OrderID = NEW.OrderID;

        IF v_status <> 'Pending' OR v_total <> NEW.AmountPaid OR v_lines <> NEW.AmountPaid THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment must match the pending order and its items';
        END IF;

        UPDATE Orders SET OrderStatus = 'Completed' WHERE OrderID = NEW.OrderID;
    END IF;
END$$

CREATE PROCEDURE PlaceOrder(
    IN p_customer INT,
    IN p_sku VARCHAR(40),
    IN p_quantity INT,
    IN p_method VARCHAR(20),
    IN p_payment_ok BOOLEAN,
    OUT p_order_id INT,
    OUT p_failure_id BIGINT
)
BEGIN
    DECLARE v_inventory INT DEFAULT NULL;
    DECLARE v_stock INT DEFAULT NULL;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_order INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET p_order_id = NULL, p_failure_id = NULL;
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be positive';
    END IF;
    IF p_payment_ok IS NULL OR p_payment_ok NOT IN (0, 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Enter 1 for success or 0 for simulated decline';
    END IF;
    IF p_method IS NULL OR p_method NOT IN ('UPI', 'Card', 'Net Banking', 'Cash on Delivery') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unsupported payment method';
    END IF;

    START TRANSACTION;
    SELECT InventoryID, StockQuantity INTO v_inventory, v_stock
    FROM Inventory WHERE SKU = p_sku FOR UPDATE;

    IF v_inventory IS NULL OR v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SKU missing or insufficient inventory stock';
    END IF;

    SELECT p.Price INTO v_price
    FROM Inventory i JOIN Product p ON p.ProductID = i.ProductID
    WHERE i.InventoryID = v_inventory;
    SET v_total = v_price * p_quantity;

    INSERT INTO Orders (CustomerID, TotalAmount) VALUES (p_customer, v_total);
    SET v_order = LAST_INSERT_ID();

    -- VALUES lets the trigger update Inventory without sharing its source table.
    INSERT INTO OrderItems (OrderID, InventoryID, Quantity, PriceAtPurchase)
    VALUES (v_order, v_inventory, p_quantity, v_price);

    IF p_payment_ok THEN
        INSERT INTO Payment (OrderID, PaymentMethod, PaymentStatus, AmountPaid)
        VALUES (v_order, p_method, 'Success', v_total);
        COMMIT;
        SET p_order_id = v_order;
    ELSE
        INSERT INTO Payment (OrderID, PaymentMethod, PaymentStatus, AmountPaid)
        VALUES (v_order, p_method, 'Failed', 0);
        ROLLBACK;

        -- The separate audit records the stock restored by undoing this checkout.
        START TRANSACTION;
        INSERT INTO CheckoutFailure
            (CustomerID, InventoryID, AttemptedOrderID, PaymentMethod, RequestedQuantity,
             StockBefore, StockAfterRollback, FailureReason)
        VALUES (p_customer, v_inventory, v_order, p_method, p_quantity,
                v_stock, v_stock, 'Simulated payment decline');
        SET p_failure_id = LAST_INSERT_ID();
        COMMIT;
    END IF;
END$$

CREATE PROCEDURE AddStock(IN p_sku VARCHAR(40), IN p_quantity INT)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_inventory INT DEFAULT NULL;
    DECLARE v_stock INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Restock quantity must be positive';
    END IF;
    START TRANSACTION;
    SELECT InventoryID, StockQuantity INTO v_inventory, v_stock
    FROM Inventory WHERE SKU = p_sku FOR UPDATE;
    IF v_inventory IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SKU not found';
    END IF;

    UPDATE Inventory SET StockQuantity = v_stock + p_quantity
    WHERE InventoryID = v_inventory;
    INSERT INTO InventoryMovement
        (InventoryID, OrderID, MovementType, PreviousStock, CurrentStock)
    VALUES (v_inventory, NULL, 'Restock', v_stock, v_stock + p_quantity);
    COMMIT;
END$$

DELIMITER ;
