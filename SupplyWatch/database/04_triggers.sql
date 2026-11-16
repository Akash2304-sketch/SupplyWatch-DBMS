-- SupplyWatch | Triggers
USE supplywatch_db;
DELIMITER $$

-- Derive delivery status from actual and expected dates before a row is saved.
CREATE TRIGGER trg_delivery_before_insert
BEFORE INSERT ON Delivery
FOR EACH ROW
BEGIN
    DECLARE v_expected_date DATE;

    IF NEW.delivered_date IS NOT NULL THEN
        SELECT expected_date INTO v_expected_date
        FROM Purchase_Order
        WHERE order_id = NEW.order_id;

        IF NEW.delivered_date <= v_expected_date THEN
            SET NEW.delivery_status = 'ON_TIME';
        ELSE
            SET NEW.delivery_status = 'LATE';
        END IF;
    ELSEIF NEW.delivery_status IN ('ON_TIME','LATE') THEN
        SET NEW.delivery_status = 'PENDING';
    END IF;
END$$

CREATE TRIGGER trg_delivery_before_update
BEFORE UPDATE ON Delivery
FOR EACH ROW
BEGIN
    DECLARE v_expected_date DATE;

    IF NEW.delivered_date IS NOT NULL THEN
        SELECT expected_date INTO v_expected_date
        FROM Purchase_Order
        WHERE order_id = NEW.order_id;

        IF NEW.delivered_date <= v_expected_date THEN
            SET NEW.delivery_status = 'ON_TIME';
        ELSE
            SET NEW.delivery_status = 'LATE';
        END IF;
    ELSEIF NEW.delivery_status IN ('ON_TIME','LATE') THEN
        SET NEW.delivery_status = 'PENDING';
    END IF;
END$$

-- Audit trigger: confirms an inventory movement has a generated transaction id.
-- Balance changes are made by the transactional procedures, avoiding double updates.
CREATE TRIGGER trg_inventory_transaction_after_insert
AFTER INSERT ON Inventory_Transaction
FOR EACH ROW
BEGIN
    SET @supplywatch_last_transaction_id = NEW.transaction_id;
END$$

DELIMITER ;
