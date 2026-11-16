-- SupplyWatch | Stored procedures
USE supplywatch_db;
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_receive_order$$
CREATE PROCEDURE sp_receive_order(
    IN p_order_id INT,
    IN p_product_id INT,
    IN p_received_qty INT,
    IN p_delivery_date DATE
)
proc: BEGIN
    DECLARE v_expected_date DATE;
    DECLARE v_status VARCHAR(30);
    DECLARE v_order_qty INT DEFAULT NULL;
    DECLARE v_received_qty INT DEFAULT NULL;
    DECLARE v_new_received INT;
    DECLARE v_remaining INT;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_received_qty IS NULL OR p_received_qty <= 0 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Received quantity must be greater than zero';
    END IF;

    START TRANSACTION;

    SET v_not_found = FALSE;
    SELECT expected_date, order_status
      INTO v_expected_date, v_status
      FROM Purchase_Order
      WHERE order_id = p_order_id
      FOR UPDATE;

    IF v_not_found THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Purchase order does not exist';
    END IF;

    IF v_status = 'CANCELLED' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Cannot receive a cancelled order';
    END IF;

    SET v_not_found = FALSE;
    SELECT quantity, received_quantity
      INTO v_order_qty, v_received_qty
      FROM Order_Item
      WHERE order_id = p_order_id AND product_id = p_product_id
      FOR UPDATE;

    IF v_not_found THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Product is not part of this purchase order';
    END IF;

    SET v_new_received = v_received_qty + p_received_qty;
    IF v_new_received > v_order_qty THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Received quantity exceeds ordered quantity';
    END IF;

    UPDATE Order_Item
       SET received_quantity = v_new_received
     WHERE order_id = p_order_id AND product_id = p_product_id;

    INSERT INTO Inventory (product_id, current_stock)
    VALUES (p_product_id, 0)
    ON DUPLICATE KEY UPDATE product_id = VALUES(product_id);

    UPDATE Inventory
       SET current_stock = current_stock + p_received_qty
     WHERE product_id = p_product_id;

    INSERT INTO Inventory_Transaction
      (product_id, transaction_type, quantity, reference_type, reference_id, notes)
    VALUES
      (p_product_id, 'IN', p_received_qty, 'PURCHASE_ORDER',
       CAST(p_order_id AS CHAR), 'Stock received against purchase order');

    SELECT SUM(quantity - received_quantity)
      INTO v_remaining
      FROM Order_Item
      WHERE order_id = p_order_id;

    IF v_remaining = 0 THEN
        UPDATE Purchase_Order SET order_status = 'COMPLETED'
        WHERE order_id = p_order_id;
        INSERT INTO Delivery (order_id, delivered_date, delivery_status, notes)
        VALUES (p_order_id, p_delivery_date, 'PENDING', 'Completed receipt')
        ON DUPLICATE KEY UPDATE
          delivered_date = p_delivery_date,
          notes = 'Completed receipt';
    ELSE
        UPDATE Purchase_Order SET order_status = 'PARTIALLY_RECEIVED'
        WHERE order_id = p_order_id;
        INSERT INTO Delivery (order_id, delivered_date, delivery_status, notes)
        VALUES (p_order_id, NULL, 'PENDING', 'Partial receipt; items remain outstanding')
        ON DUPLICATE KEY UPDATE
          notes = 'Partial receipt; items remain outstanding';
    END IF;

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_record_stock_issue$$
CREATE PROCEDURE sp_record_stock_issue(
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_notes VARCHAR(255)
)
BEGIN
    DECLARE v_stock INT DEFAULT NULL;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Issue quantity must be greater than zero';
    END IF;

    START TRANSACTION;

    SET v_not_found = FALSE;
    SELECT current_stock INTO v_stock
      FROM Inventory
      WHERE product_id = p_product_id
      FOR UPDATE;

    IF v_not_found THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Inventory record does not exist for this product';
    END IF;

    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Insufficient stock: issue cancelled';
    END IF;

    UPDATE Inventory
       SET current_stock = current_stock - p_quantity
     WHERE product_id = p_product_id;

    INSERT INTO Inventory_Transaction
      (product_id, transaction_type, quantity, reference_type, reference_id, notes)
    VALUES
      (p_product_id, 'OUT', p_quantity, 'STOCK_ISSUE', NULL, p_notes);

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_recalculate_delivery_status$$
CREATE PROCEDURE sp_recalculate_delivery_status(IN p_order_id INT)
BEGIN
    UPDATE Delivery d
    JOIN Purchase_Order po ON po.order_id = d.order_id
       SET d.delivery_status =
           CASE
             WHEN d.delivered_date IS NULL THEN 'PENDING'
             WHEN d.delivered_date <= po.expected_date THEN 'ON_TIME'
             ELSE 'LATE'
           END
     WHERE d.order_id = p_order_id;
END$$

DELIMITER ;
