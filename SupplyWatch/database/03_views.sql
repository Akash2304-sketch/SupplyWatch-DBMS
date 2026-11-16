-- SupplyWatch | Reporting views
USE supplywatch_db;

CREATE OR REPLACE VIEW v_inventory_risk AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    i.current_stock,
    p.reorder_level,
    p.unit_price,
    (i.current_stock * p.unit_price) AS stock_value,
    CASE
      WHEN i.current_stock = 0 THEN 'STOCKOUT'
      WHEN i.current_stock <= p.reorder_level THEN 'REORDER NOW'
      WHEN i.current_stock <= p.reorder_level * 1.5 THEN 'WATCH'
      ELSE 'HEALTHY'
    END AS risk_level,
    s.supplier_name AS preferred_supplier
FROM Product p
JOIN Inventory i ON i.product_id = p.product_id
LEFT JOIN Supplier s ON s.supplier_id = p.preferred_supplier_id
WHERE p.active = TRUE;

CREATE OR REPLACE VIEW v_supplier_performance AS
SELECT
    s.supplier_id,
    s.supplier_name,
    s.supplier_status,
    COUNT(DISTINCT CASE
      WHEN po.order_status <> 'CANCELLED' AND d.delivered_date IS NOT NULL
      THEN po.order_id END) AS completed_deliveries,
    COUNT(DISTINCT CASE
      WHEN po.order_status <> 'CANCELLED' AND d.delivered_date IS NOT NULL
       AND d.delivered_date <= po.expected_date
      THEN po.order_id END) AS on_time_deliveries,
    ROUND(
      100.0 * COUNT(DISTINCT CASE
        WHEN po.order_status <> 'CANCELLED' AND d.delivered_date IS NOT NULL
         AND d.delivered_date <= po.expected_date
        THEN po.order_id END)
      / NULLIF(COUNT(DISTINCT CASE
        WHEN po.order_status <> 'CANCELLED' AND d.delivered_date IS NOT NULL
        THEN po.order_id END), 0), 2
    ) AS on_time_percentage,
    COUNT(DISTINCT CASE
      WHEN po.order_status <> 'CANCELLED' AND d.delivered_date IS NOT NULL
       AND d.delivered_date > po.expected_date
      THEN po.order_id END) AS late_deliveries,
    COUNT(DISTINCT CASE
      WHEN po.order_status IN ('PLACED','PARTIALLY_RECEIVED')
      THEN po.order_id END) AS open_orders
FROM Supplier s
LEFT JOIN Purchase_Order po ON po.supplier_id = s.supplier_id
LEFT JOIN Delivery d ON d.order_id = po.order_id
GROUP BY s.supplier_id, s.supplier_name, s.supplier_status;

CREATE OR REPLACE VIEW v_open_purchase_orders AS
SELECT
    po.order_id,
    po.order_number,
    s.supplier_name,
    po.order_date,
    po.expected_date,
    po.order_status,
    DATEDIFF(CURRENT_DATE, po.expected_date) AS days_past_expected,
    SUM(oi.quantity * oi.unit_price) AS order_value
FROM Purchase_Order po
JOIN Supplier s ON s.supplier_id = po.supplier_id
LEFT JOIN Order_Item oi ON oi.order_id = po.order_id
WHERE po.order_status IN ('PLACED','PARTIALLY_RECEIVED')
GROUP BY po.order_id, po.order_number, s.supplier_name,
         po.order_date, po.expected_date, po.order_status;

CREATE OR REPLACE VIEW v_inventory_valuation AS
SELECT
    p.category,
    COUNT(*) AS product_count,
    SUM(i.current_stock) AS total_units,
    ROUND(SUM(i.current_stock * p.unit_price), 2) AS total_inventory_value
FROM Product p
JOIN Inventory i ON i.product_id = p.product_id
WHERE p.active = TRUE
GROUP BY p.category;
