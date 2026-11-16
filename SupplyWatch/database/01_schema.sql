-- SupplyWatch | Schema | MySQL 8.0+
-- Safe to rerun in a development environment. WARNING: drops this project's tables.
CREATE DATABASE IF NOT EXISTS supplywatch_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE supplywatch_db;

SET FOREIGN_KEY_CHECKS = 0;
DROP VIEW IF EXISTS v_inventory_risk;
DROP VIEW IF EXISTS v_supplier_performance;
DROP VIEW IF EXISTS v_open_purchase_orders;
DROP VIEW IF EXISTS v_inventory_valuation;
DROP TRIGGER IF EXISTS trg_delivery_before_insert;
DROP TRIGGER IF EXISTS trg_delivery_before_update;
DROP TRIGGER IF EXISTS trg_inventory_transaction_after_insert;
DROP PROCEDURE IF EXISTS sp_receive_order;
DROP PROCEDURE IF EXISTS sp_record_stock_issue;
DROP PROCEDURE IF EXISTS sp_recalculate_delivery_status;
DROP TABLE IF EXISTS Supplier_Evaluation;
DROP TABLE IF EXISTS Inventory_Transaction;
DROP TABLE IF EXISTS Delivery;
DROP TABLE IF EXISTS Order_Item;
DROP TABLE IF EXISTS Purchase_Order;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Supplier;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Supplier (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(120),
    address VARCHAR(255),
    standard_lead_days INT NOT NULL DEFAULT 7,
    supplier_status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_supplier_phone UNIQUE (phone),
    CONSTRAINT uq_supplier_email UNIQUE (email),
    CONSTRAINT chk_supplier_lead_days CHECK (standard_lead_days >= 0)
) ENGINE=InnoDB;

CREATE TABLE Product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(30) NOT NULL,
    product_name VARCHAR(120) NOT NULL,
    category VARCHAR(60) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    reorder_level INT NOT NULL DEFAULT 10,
    preferred_supplier_id INT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_sku UNIQUE (sku),
    CONSTRAINT chk_product_price CHECK (unit_price >= 0),
    CONSTRAINT chk_product_reorder CHECK (reorder_level >= 0),
    CONSTRAINT fk_product_supplier FOREIGN KEY (preferred_supplier_id)
      REFERENCES Supplier(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Inventory (
    product_id INT PRIMARY KEY,
    current_stock INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_inventory_stock CHECK (current_stock >= 0),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
      REFERENCES Product(product_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Purchase_Order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(30) NOT NULL,
    supplier_id INT NOT NULL,
    order_date DATE NOT NULL,
    expected_date DATE NOT NULL,
    order_status ENUM('PLACED','PARTIALLY_RECEIVED','COMPLETED','CANCELLED')
      NOT NULL DEFAULT 'PLACED',
    notes VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_order_number UNIQUE (order_number),
    CONSTRAINT chk_order_dates CHECK (expected_date >= order_date),
    CONSTRAINT fk_order_supplier FOREIGN KEY (supplier_id)
      REFERENCES Supplier(supplier_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_order_supplier_date (supplier_id, order_date),
    INDEX idx_order_status_expected (order_status, expected_date)
) ENGINE=InnoDB;

CREATE TABLE Order_Item (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    received_quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT chk_order_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_item_price CHECK (unit_price >= 0),
    CONSTRAINT chk_received_quantity CHECK (received_quantity >= 0 AND received_quantity <= quantity),
    CONSTRAINT fk_item_order FOREIGN KEY (order_id)
      REFERENCES Purchase_Order(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_item_product FOREIGN KEY (product_id)
      REFERENCES Product(product_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_order_item_product (product_id)
) ENGINE=InnoDB;

-- One delivery event per purchase order in this portfolio version.
-- The design can be extended to multiple shipment events if needed.
CREATE TABLE Delivery (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    delivered_date DATE NULL,
    delivery_status ENUM('PENDING','ON_TIME','LATE','NOT_DELIVERED')
      NOT NULL DEFAULT 'PENDING',
    notes VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_delivery_order UNIQUE (order_id),
    CONSTRAINT fk_delivery_order FOREIGN KEY (order_id)
      REFERENCES Purchase_Order(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_delivery_status_date (delivery_status, delivered_date)
) ENGINE=InnoDB;

CREATE TABLE Inventory_Transaction (
    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    transaction_type ENUM('IN','OUT','ADJUSTMENT') NOT NULL,
    quantity INT NOT NULL,
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_type VARCHAR(30),
    reference_id VARCHAR(40),
    notes VARCHAR(255),
    CONSTRAINT chk_transaction_quantity CHECK (quantity > 0),
    CONSTRAINT fk_transaction_product FOREIGN KEY (product_id)
      REFERENCES Product(product_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_transaction_product_date (product_id, transaction_date)
) ENGINE=InnoDB;

CREATE TABLE Supplier_Evaluation (
    evaluation_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    evaluation_date DATE NOT NULL,
    on_time_percentage DECIMAL(5,2) NULL,
    performance_score DECIMAL(5,2) NOT NULL,
    remarks VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_eval_ontime CHECK (on_time_percentage BETWEEN 0 AND 100),
    CONSTRAINT chk_eval_score CHECK (performance_score BETWEEN 0 AND 100),
    CONSTRAINT fk_evaluation_supplier FOREIGN KEY (supplier_id)
      REFERENCES Supplier(supplier_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_evaluation_supplier_date (supplier_id, evaluation_date)
) ENGINE=InnoDB;
